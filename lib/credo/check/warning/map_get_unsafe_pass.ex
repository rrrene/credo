defmodule Credo.Check.Warning.MapGetUnsafePass do
  @moduledoc """
  `Map.get/2` can lead into runtime errors if the result is passed into a pipe
  without a proper default value. This happens when the next function in the
  pipe cannot handle `nil` values correctly.

  Example:

        %{foo: [1, 2 ,3], bar: [4, 5, 6]}
        |> Map.get(:baz)
        |> Enum.each(&IO.puts/1)

  This will cause a `Protocol.UndefinedError`, since `nil` isn't `Enumerable`.
  Often times while iterating over enumerables zero iterations is preferrable
  to being forced to deal with an exception. Had there been a `[]` default
  parameter this could have been averted.

  Encourage use of `Map.get/3` instead to provide safer default values.
  """

  @explanation [check: @moduledoc]
  @call_string "Map.get"

  use Credo.Check, base_priority: :normal

  @doc false
  def run(%SourceFile{} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse({:|>, _meta , _args} = ast, issues, issue_meta) do
    pipe_issues =
      ast
      |> Macro.unpipe
      |> Enum.drop(-1) # The last expression doesn't really matter
      |> Enum.with_index
      |> Enum.filter_map(&unsafe_expr?/1,
                         fn ({expr, _}) ->
                           {{{_, meta, _}, _, _}, _} = expr
                           issue_for(issue_meta, meta[:line], @call_string)
                         end)
    {ast, issues ++ pipe_issues}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp unsafe_expr?({expr, idx}) do
    required_length =
      case idx do
        0 -> 3
        _ -> 2
      end

    case expr do
      {{{:., _, [{_, _, [:Map]}, :get]}, _, args}, _} ->
        length(args) != required_length
      _ ->
        false
    end
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue issue_meta,
      message: "Map.get with no default return value is potentially unsafe
                in pipes, use Map.get/3 instead",
      trigger: trigger,
      line_no: line_no
  end
end
