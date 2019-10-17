defmodule Credo.Check.Readability.SeparateAliasRequire do
  @checkdoc """
    All instances of alias should be consecutive within a file.
    Likewise, all instances of require should be consecutive within a file.

    For example:

    defmodule Foo do
      require Logger
      alias Foo.Bar

      alias Foo.Baz
      require Integer

      ...
    end

    should be changed to:

    defmodule Foo do
      require Integer
      require Logger

      alias Foo.Bar
      alias Foo.Baz

      ...
    end
  """

  @explanation [
    check: @checkdoc,
    params: []
  ]
  @default_params []

  # you can configure the basics of your check via the `use Credo.Check` call
  use Credo.Check, base_priority: :low

  alias Credo.Code

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    line_map =
      source_file
      |> to_types()
      |> Enum.into(%{})

    [:alias, :require]
    |> Enum.map(&find_issue(&1, line_map, issue_meta))
    |> Enum.reject(&is_nil/1)
  end

  defp to_types(source_file) do
    Code.prewalk(source_file, &traverse(&1, &2))
  end

  defp line_number({_, opts, _}), do: Keyword.get(opts, :line)

  defp traverse({:quote, _, _} = _ast, acc) do
    {nil, acc}
  end

  defp traverse({:alias, _, [{:__aliases__, _, _}, [as: as_ast]]} = ast, acc) do
    alias_line_number = line_number(ast)
    as_line_number = line_number(as_ast)

    if alias_line_number == as_line_number do
      {ast, [{alias_line_number, :alias} | acc]}
    else
      lines = [alias_line_number - 1, alias_line_number, as_line_number, as_line_number + 1]
      {ast, acc ++ Enum.map(lines, &{&1, :alias})}
    end
  end

  defp traverse(
         {:alias, _, [{{_, _, [{:__aliases__, _, _base_alias}, :{}]}, _, multi_aliases}]} = ast,
         acc
       ) do
    base_line_number = line_number(ast)

    acc =
      case multi_aliases do
        [] ->
          acc

        [hd | _] ->
          if line_number(hd) == base_line_number do
            # single line multi-alias
            [{base_line_number, :alias} | acc]
          else
            # multiple line multi-alias
            lines = Enum.map(multi_aliases, &line_number/1)

            max = Enum.max(lines)
            lines = [max + 1, max + 2, base_line_number, base_line_number - 1 | lines]
            acc ++ Enum.map(lines, &{&1, :alias})
          end
      end

    {ast, acc}
  end

  defp traverse({type, _, [{:__aliases__, _, _} | _]} = ast, acc)
       when type in [:alias, :require],
       do: {ast, [{line_number(ast), type} | acc]}

  defp traverse(ast, acc) do
    {ast, acc}
  end

  defp find_issue(type, line_map, issue_meta) do
    line_map
    |> Enum.filter(&(elem(&1, 1) == type))
    |> Enum.map(&elem(&1, 0))
    |> Enum.sort()
    |> is_issue(type, issue_meta)
  end

  defp is_issue([], _, _), do: nil
  defp is_issue([_], _, _), do: nil

  defp is_issue([x, y | tl], type, issue_meta) when x == y - 1,
    do: is_issue([y | tl], type, issue_meta)

  defp is_issue([_x, y | _], type, issue_meta), do: issue_for(issue_meta, y, type)

  defp issue_for(issue_meta, line_no, type) do
    format_issue(issue_meta,
      message: "#{plural(type)} should be consecutive within a file",
      line_no: line_no
    )
  end

  defp plural(:alias), do: "aliases"
  defp plural(:require), do: "requires"
end
