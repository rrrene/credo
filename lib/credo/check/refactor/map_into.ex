defmodule Credo.Check.Refactor.MapInto do
  # only avaible in Elixir < 1.8 since performance improvements have since made this check obsolete
  use Credo.Check,
    base_priority: :high,
    elixir_version: "< 1.8.0",
    explanations: [
      check: """
      `Enum.into/3` is more efficient than `Enum.map/2 |> Enum.into/2`.

      This should be refactored:

          [:apple, :banana, :carrot]
          |> Enum.map(&({&1, to_string(&1)}))
          |> Enum.into(%{})

      to look like this:

          Enum.into([:apple, :banana, :carrot], %{}, &({&1, to_string(&1)}))

      The reason for this is performance, because the separate calls to
      `Enum.map/2` and `Enum.into/2` require two iterations whereas
      `Enum.into/3` only requires one.
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse(
         {{:., _, [{:__aliases__, meta, [:Enum]}, :into]}, _,
          [{{:., _, [{:__aliases__, _, [:Enum]}, :map]}, _, _}, _]} = ast,
         issues,
         issue_meta
       ) do
    new_issue = issue_for(issue_meta, meta[:line], "map_into")

    {ast, issues ++ List.wrap(new_issue)}
  end

  defp traverse(
         {:|>, meta,
          [
            {{:., _, [{:__aliases__, _, [:Enum]}, :map]}, _, _},
            {{:., _, [{:__aliases__, _, [:Enum]}, :into]}, _, _}
          ]} = ast,
         issues,
         issue_meta
       ) do
    new_issue = issue_for(issue_meta, meta[:line], "map_into")

    {ast, issues ++ List.wrap(new_issue)}
  end

  defp traverse(
         {{:., meta, [{:__aliases__, _, [:Enum]}, :into]}, _,
          [
            {:|>, _, [_, {{:., _, [{:__aliases__, _, [:Enum]}, :map]}, _, _}]},
            _
          ]} = ast,
         issues,
         issue_meta
       ) do
    new_issue = issue_for(issue_meta, meta[:line], "map_into")

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
            {{:., _, [{:__aliases__, _, [:Enum]}, :into]}, _, into_args}
          ]} = ast,
         issues,
         issue_meta
       )
       when length(into_args) == 1 do
    new_issue = issue_for(issue_meta, meta[:line], "map_into")

    {ast, issues ++ List.wrap(new_issue)}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message: "`Enum.into/3` is more efficient than `Enum.map/2 |> Enum.into/2`",
      trigger: trigger,
      line_no: line_no
    )
  end
end
