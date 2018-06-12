defmodule Credo.Check.Refactor.MapMap do
  @moduledoc """
  One `Enum.map/2` is more efficient than `Enum.map/2 |> Enum.map/2`.

  This should be refactored:

      [:a, :b, :c]
      |> Enum.map(&inspect/1)
      |> Enum.map(&String.upcase/1)

  to look like this:

      Enum.map([:a, :b, :c], fn letter ->
        letter
        |> inspect()
        |> String.upcase()
      end)

  The reason for this is performance, because the two separate calls
  to `Enum.map/2` require two iterations whereas doing the functions
  in the single `Enum.map/2` only requires one.
  """

  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :high

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse(
         ast =
           {{:., _, [{:__aliases__, meta, [:Enum]}, :map]}, _,
            [{{:., _, [{:__aliases__, _, [:Enum]}, :map]}, _, _}, _]},
         issues,
         issue_meta
       ) do
    new_issue = issue_for(issue_meta, meta[:line], "map_map")
    {ast, issues ++ List.wrap(new_issue)}
  end

  defp traverse(
         ast =
           {:|>, meta,
            [
              {{:., _, [{:__aliases__, _, [:Enum]}, :map]}, _, _},
              {{:., _, [{:__aliases__, _, [:Enum]}, :map]}, _, _}
            ]},
         issues,
         issue_meta
       ) do
    new_issue = issue_for(issue_meta, meta[:line], "map_map")
    {ast, issues ++ List.wrap(new_issue)}
  end

  defp traverse(
         ast =
           {{:., meta, [{:__aliases__, _, [:Enum]}, :map]}, _,
            [
              {:|>, _, [_, {{:., _, [{:__aliases__, _, [:Enum]}, :map]}, _, _}]},
              _
            ]},
         issues,
         issue_meta
       ) do
    new_issue = issue_for(issue_meta, meta[:line], "map_map")
    {ast, issues ++ List.wrap(new_issue)}
  end

  defp traverse(
         ast =
           {:|>, meta,
            [
              {:|>, _,
               [
                 _,
                 {{:., _, [{:__aliases__, _, [:Enum]}, :map]}, _, _}
               ]},
              {{:., _, [{:__aliases__, _, [:Enum]}, :map]}, _, _}
            ]},
         issues,
         issue_meta
       ) do
    new_issue = issue_for(issue_meta, meta[:line], "map_map")
    {ast, issues ++ List.wrap(new_issue)}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message: "One `Enum.map/2` is more efficient than `Enum.map/2 |> Enum.map/2`",
      trigger: trigger,
      line_no: line_no
    )
  end
end
