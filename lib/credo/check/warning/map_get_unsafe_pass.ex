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

    {ast, case is_unsafe?(order) do
            true -> issues_for_call(meta, issues, issue_meta)
            false -> issues
          end}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp pipewalk({:|>, _meta, [left | right]} = _ast) do
    pipewalk(left) ++ pipewalk(List.first(right))
  end

  defp pipewalk({{:., _, [{:__aliases__, _, [namespace]}, callable]}, _, args}) do
    [{"#{namespace}.#{callable}", args}]
  end

  defp pipewalk({value, _meta, args} = _ast) when is_atom(value),  do: [{value, args}]
  defp pipewalk({value, _meta, []} = _ast),  do: [{value}]
  defp pipewalk({value, _meta, nil} = _ast), do: [{value}]

  defp is_unsafe?(expression) do
    len = Enum.count(expression) - 1
    {_, expression} = List.pop_at(expression, len)

    true in Enum.map(expression, fn x ->
                                   case x do
                                     {"Map.get", [head | _]} when is_atom(head) -> true
                                     {"Map.get", [head | tail]} when is_tuple(head) -> Enum.count(tail) < 2
                                     {"Map.get", [_]} -> true
                                     _ -> false
                                   end
                                 end)
  end

  def issues_for_call(meta, issues, issue_meta) do
    [issue_for(issue_meta, meta[:line], @call_string) | issues]
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue issue_meta,
      message: "Map.get/2 is unsafe in pipes, use Map.get/3",
      trigger: trigger,
      line_no: line_no
  end
end
