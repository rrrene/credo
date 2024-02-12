defmodule Credo.Check.Refactor.FilterCount do
  use Credo.Check,
    id: "EX4030",
    base_priority: :high,
    explanations: [
      check: """
      `Enum.count/2` is more efficient than `Enum.filter/2 |> Enum.count/1`.

      This should be refactored:

          [1, 2, 3, 4, 5]
          |> Enum.filter(fn x -> rem(x, 3) == 0 end)
          |> Enum.count()

      to look like this:

          Enum.count([1, 2, 3, 4, 5], fn x -> rem(x, 3) == 0 end)

      The reason for this is performance, because the two separate calls
      to `Enum.filter/2` and `Enum.count/1` require two iterations whereas
      `Enum.count/2` performs the same work in one pass.
      """
    ]

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse(
         {:|>, _,
          [
            {:|>, _,
             [
               _,
               {{:., _, [{:__aliases__, _, [:Enum]}, :filter]}, _, _}
             ]},
            {{:., meta, [{:__aliases__, _, [:Enum]}, :count]}, _, []}
          ]} = ast,
         issues,
         issue_meta
       ) do
    new_issue = issue_for(issue_meta, meta[:line], "count")
    {ast, issues ++ List.wrap(new_issue)}
  end

  defp traverse(
         {{:., meta, [{:__aliases__, _, [:Enum]}, :count]}, _,
          [
            {{:., _, [{:__aliases__, _, [:Enum]}, :filter]}, _, _}
          ]} = ast,
         issues,
         issue_meta
       ) do
    new_issue = issue_for(issue_meta, meta[:line], "count")
    {ast, issues ++ List.wrap(new_issue)}
  end

  defp traverse(
         {:|>, _,
          [
            {{:., _, [{:__aliases__, _, [:Enum]}, :filter]}, _, _},
            {{:., meta, [{:__aliases__, _, [:Enum]}, :count]}, _, []}
          ]} = ast,
         issues,
         issue_meta
       ) do
    new_issue = issue_for(issue_meta, meta[:line], "count")
    {ast, issues ++ List.wrap(new_issue)}
  end

  defp traverse(
         {{:., meta, [{:__aliases__, _, [:Enum]}, :count]}, _,
          [
            {:|>, _, [_, {{:., _, [{:__aliases__, _, [:Enum]}, :filter]}, _, _}]}
          ]} = ast,
         issues,
         issue_meta
       ) do
    new_issue = issue_for(issue_meta, meta[:line], "count")
    {ast, issues ++ List.wrap(new_issue)}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message: "`Enum.count/2` is more efficient than `Enum.filter/2 |> Enum.count/1`.",
      trigger: trigger,
      line_no: line_no
    )
  end
end
