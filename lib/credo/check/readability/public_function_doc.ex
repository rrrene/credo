defmodule Credo.Check.Readability.PublicFunctionDoc do
  @moduledoc false

  @checkdoc """
  Every public function should be documented.

      # preferred

      @doc \"\"\"
      Does something useful.
      \"\"\"
      def public_function do
        "do something"
      end

      # also okay: explicitly say there is no documentation

      @doc false
      def public_function do
        "do something"
      end

  In most cases, adding documentation to public functions is beneficial to
  your future self and anyone else who is working with your code base.
  Well documented functions save people time and headache by clearly
  articulating the contract between the function and the user. With a
  documented function, people can easily abstract at higher levels
  without the need to be concerned with lower level implemenation details.
  If, however, you decide to not document a function, Elixir prefers
  explicitness over implicit behavior. You can "tag" these undocumented
  public functions with

      @doc false

  to make it clear that there is no intention in documenting it.
  """
  @explanation [
    check: @checkdoc,
    params: [
      ignore_names: "All functions matching this regex (or list of regexes) will be ignored."
    ]
  ]
  @default_params [
    ignore_names: []
  ]

  use Credo.Check

  @doc false
  def run(%SourceFile{filename: filename} = source_file, params \\ []) do
    if Path.extname(filename) == ".exs" do
      []
    else
      issue_meta = IssueMeta.for(source_file, params)
      ignore_names = Params.get(params, :ignore_names, @default_params)

      {_continue, issues} =
        Credo.Code.prewalk(
          source_file,
          &traverse(&1, &2, issue_meta, ignore_names),
          {true, []}
        )

      issues
    end
  end

  defp traverse([do: {:__block__, [], do_block}] = ast, {true, issues}, issue_meta, ignore_names) do
    new_issues =
      do_block
      |> find_func_issues(issue_meta, ignore_names)
      |> Enum.reverse()

    {ast, {true, issues ++ new_issues}}
  end

  defp traverse(ast, {continue, issues}, _, _) do
    {ast, {continue, issues}}
  end

  defp find_func_issues(do_block, issue_meta, ignore_names) do
    do_find_func_issues(do_block, issue_meta, ignore_names, [])
  end

  defp do_find_func_issues(
         [{:@, _, [{:doc, _, [false]}]} | tail] = _do_block,
         issue_meta,
         ignore_names,
         issues
       ),
       do: skip_func(tail, issue_meta, ignore_names, issues)

  defp do_find_func_issues(
         [{:@, _, [{:doc, _, [string]}]} | tail] = _do_block,
         issue_meta,
         ignore_names,
         issues
       )
       when is_binary(string) do
    if String.trim(string) == "" do
      {:def, meta, _} = get_func(tail)

      issue =
        issue_for(
          "Use `@doc false` if a function will not be documented.",
          issue_meta,
          meta[:line],
          meta
        )

      skip_func(tail, issue_meta, ignore_names, [issue | issues])
    else
      skip_func(tail, issue_meta, ignore_names, issues)
    end
  end

  defp do_find_func_issues(
         [{:def, meta, [{name, _, _}, _]} = head | tail] = _do_block,
         issue_meta,
         ignore_names,
         issues
       ) do
    cond do
      matches_any?(name, ignore_names) ->
        skip_func(tail, issue_meta, ignore_names, issues)

      prefixed_func?(head) ->
        skip_func(tail, issue_meta, ignore_names, issues)

      true ->
        issue =
          issue_for(
            "Use `@doc false` if a function will not be documented.",
            issue_meta,
            meta[:line],
            name
          )

        do_find_func_issues(tail, issue_meta, ignore_names, [issue | issues])
    end
  end

  defp do_find_func_issues([_ | tail] = _do_block, issue_meta, ignore_names, issues) do
    do_find_func_issues(tail, issue_meta, ignore_names, issues)
  end

  defp do_find_func_issues([], _, _, issues), do: issues

  defp get_func([
         {:def, _, _} = func
         | _
       ]) do
    func
  end

  defp get_func([_ | tail]) do
    tail
  end

  defp skip_func(
         [
           {:def, _, _}
           | tail
         ],
         issue_meta,
         ignore_names,
         issues
       ) do
    do_find_func_issues(tail, issue_meta, ignore_names, issues)
  end

  defp skip_func([_ | tail], issue_meta, ignore_names, issues),
    do: skip_func(tail, issue_meta, ignore_names, issues)

  defp skip_func([], issue_meta, ignore_names, issues),
    do: do_find_func_issues([], issue_meta, ignore_names, issues)

  defp prefixed_func?({:def, _, [{name, _, _}, _]}) do
    name
    |> Atom.to_string()
    |> String.starts_with?("_")
  end

  defp prefixed_func?(_), do: false

  defp matches_any?(name, list) when is_list(list) do
    Enum.any?(list, &matches_any?(name, &1))
  end

  defp matches_any?(name, string) when is_binary(string) do
    String.contains?(to_string(name), string)
  end

  defp matches_any?(name, atom) when is_atom(atom) do
    name == atom
  end

  defp matches_any?(name, regex) do
    String.match?(to_string(name), regex)
  end

  defp issue_for(message, issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message: message,
      trigger: trigger,
      line_no: line_no
    )
  end
end
