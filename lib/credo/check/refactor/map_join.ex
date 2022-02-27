defmodule Credo.Check.Refactor.MapJoin do
  use Credo.Check,
    base_priority: :high,
    explanations: [
      check: """
      `Enum.map_join/3` is more efficient than `Enum.map/2 |> Enum.join/2`.

      This should be refactored:

          ["a", "b", "c"]
          |> Enum.map(&String.upcase/1)
          |> Enum.join(", ")

      to look like this:

          Enum.map_join(["a", "b", "c"], ", ", &String.upcase/1)

      The reason for this is performance, because the two separate calls
      to `Enum.map/2` and `Enum.join/2` require two iterations whereas 
      `Enum.map_join/3` performs the same work in one pass.
      """
    ]

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse(
         {{:., _, [{:__aliases__, meta, [:Enum]}, :join]}, _,
          [{{:., _, [{:__aliases__, _, [:Enum]}, :map]}, _, _}, _]} = ast,
         issues,
         issue_meta
       ) do
    new_issue = issue_for(issue_meta, meta[:line], "map_join")
    {ast, issues ++ List.wrap(new_issue)}
  end

  defp traverse(
         {:|>, meta,
          [
            {{:., _, [{:__aliases__, _, [:Enum]}, :map]}, _, _},
            {{:., _, [{:__aliases__, _, [:Enum]}, :join]}, _, _}
          ]} = ast,
         issues,
         issue_meta
       ) do
    new_issue = issue_for(issue_meta, meta[:line], "map_join")
    {ast, issues ++ List.wrap(new_issue)}
  end

  defp traverse(
         {{:., meta, [{:__aliases__, _, [:Enum]}, :join]}, _,
          [
            {:|>, _, [_, {{:., _, [{:__aliases__, _, [:Enum]}, :map]}, _, _}]},
            _
          ]} = ast,
         issues,
         issue_meta
       ) do
    new_issue = issue_for(issue_meta, meta[:line], "map_join")
    {ast, issues ++ List.wrap(new_issue)}
  end

  defp traverse(
         {:|>, meta,
          [
            {:|>, _,
             [
               _,
               {{:., _, [{:__aliases__, _, [:Enum]}, :map]}, _, _}
             ]},
            {{:., _, [{:__aliases__, _, [:Enum]}, :join]}, _, _}
          ]} = ast,
         issues,
         issue_meta
       ) do
    new_issue = issue_for(issue_meta, meta[:line], "map_join")
    {ast, issues ++ List.wrap(new_issue)}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message: "`Enum.map_join/3` is more efficient than `Enum.map/2 |> Enum.join/2`",
      trigger: trigger,
      line_no: line_no
    )
  end
end
