defmodule Credo.Check.Warning.MapGetUnsafePass do
  @moduledoc """
  `Map.get/2` can lead into runtime errors if the result is passed into a pipe without a proper default value.
  This happens when the next function in the pipe cannot handle `nil` values correctly.

  Example:

        %{foo: [1, 2 ,3], bar: [4, 5, 6]}
        |> Map.get(:baz)
        |> Enum.each(&IO.puts/1)


  This will cause a `Protocol.UndefinedError`, since `nil` isn't `Enumerable`. Often times while
  iterating over enumerables zero iterations is preferrable to being forced to deal with an exception.
  Had there been a `[]` default parameter this could have been averted.

  Encourage use of `Map.get/3` instead to provide safer default values.
  """

  @explanation [check: @moduledoc]
  @call_string "Map.get/2"

  use Credo.Check, base_priority: :high

  @doc false
  def run(%SourceFile{} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse({:|>, meta , [left | right]} = ast, [] = issues, issue_meta) do
    order = pipewalk(left) ++ pipewalk(List.first(right))

    pipe_issues = order
                  |> unsafe_lines
                  |> Enum.map(fn x -> issues_for_call([line: x || meta[:line]], issues, issue_meta) end)
                  |> List.flatten

    {ast, issues ++ pipe_issues}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp pipewalk({:|>, _meta, [left | right]} = _ast) do
    pipewalk(left) ++ pipewalk(List.first(right))
  end

  defp pipewalk({{:., meta, [{:__aliases__, _, [_namespace]}, _callable]} = ast, _, args}) do
    [{to_function_call_name(ast), args, meta[:line]}]
  end

  defp pipewalk({value, meta, args} = _ast) when is_atom(value),  do: [{value, args, meta[:line]}]
  defp pipewalk({value, meta, []} = _ast),  do: [{value, meta[:line]}]
  defp pipewalk({value, meta, nil} = _ast), do: [{value, meta[:line]}]
  defp pipewalk(any_literal),               do: [{any_literal, [], nil}]

  defp unsafe_lines(expression) do
    # The last expression inside the pipe doesn't really matter
    [head | pipe] = Enum.drop(expression, -1)

    unsafe_head = case head do
                    {"Map.get", args, line} when length(args) != 3 -> [line]
                    _ -> []
                  end

    tail_mapper = fn x, acc ->
                    acc ++ case x do
                      {"Map.get", [_], line} -> [line]
                      _ -> []
                    end
                  end

    unsafe_tail = Enum.reduce(pipe, [], tail_mapper)
    unsafe_head ++ unsafe_tail
  end

  def issues_for_call(meta, issues, issue_meta) do
    [issue_for(issue_meta, meta[:line], @call_string) | issues]
  end

  defp to_function_call_name({_, _, _} = ast) do
    {ast, [], []}
    |> Macro.to_string()
    |> String.replace(~r/\.?\(.*\)$/s, "")
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue issue_meta,
      message: "Map.get/2 is unsafe in pipes, use Map.get/3",
      trigger: trigger,
      line_no: line_no
  end
end
