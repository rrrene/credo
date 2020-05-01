defmodule Credo.Check.Warning.MapGetUnsafePass do
  use Credo.Check,
    base_priority: :normal,
    tags: [:controversial],
    explanations: [
      check: """
      `Map.get/2` can lead into runtime errors if the result is passed into a pipe
      without a proper default value. This happens when the next function in the
      pipe cannot handle `nil` values correctly.

      Example:

          %{foo: [1, 2 ,3], bar: [4, 5, 6]}
          |> Map.get(:missing_key)
          |> Enum.each(&IO.puts/1)

      This will cause a `Protocol.UndefinedError`, since `nil` isn't `Enumerable`.
      Often times while iterating over enumerables zero iterations is preferrable
      to being forced to deal with an exception. Had there been a `[]` default
      parameter this could have been averted.

      If you are sure the value exists and can't be nil, please use `Map.fetch!/2`.
      If you are not sure, `Map.get/3` can help you provide a safe default value.
      """
    ]

  @call_string "Map.get"
  @unsafe_modules [:Enum]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse({:|>, _meta, _args} = ast, issues, issue_meta) do
    pipe_issues =
      ast
      |> Macro.unpipe()
      |> Enum.with_index()
      |> find_pipe_issues(issue_meta)

    {ast, issues ++ pipe_issues}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp find_pipe_issues(pipe, issue_meta) do
    pipe
    |> Enum.reduce([], fn {expr, idx}, acc ->
      required_length = required_argument_length(idx)
      {next_expr, _} = Enum.at(pipe, idx + 1, {nil, nil})

      case {expr, nil_safe?(next_expr)} do
        {{{{:., meta, [{_, _, [:Map]}, :get]}, _, args}, _}, false}
        when length(args) != required_length ->
          acc ++ [issue_for(issue_meta, meta[:line], @call_string)]

        _ ->
          acc
      end
    end)
  end

  defp required_argument_length(idx) when idx == 0, do: 3
  defp required_argument_length(_), do: 2

  defp nil_safe?(expr) do
    case expr do
      {{{:., _, [{_, _, [module]}, _]}, _, _}, _} ->
        !(module in @unsafe_modules)

      _ ->
        true
    end
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message: "Map.get with no default return value is potentially unsafe
                in pipes, use Map.get/3 instead",
      trigger: trigger,
      line_no: line_no
    )
  end
end
