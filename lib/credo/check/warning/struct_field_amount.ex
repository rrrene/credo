defmodule Credo.Check.Warning.StructFieldAmount do
  @moduledoc false

  use Credo.Check,
    id: "EX????",
    base_priority: :normal,
    category: :warning,
    explanations: [
      check: """
      Structs in Elixir are implemented as compile-time maps, which have a predefined amount of fields.
      When structs have 32 or more fields, their internal representation in the Erlang Virtual Machines
      changes, potentially leading to bloating and higher memory usage.
      """
    ]

  alias Credo.Code.Name
  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)
    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse(
         {:defmodule, _, [{:__aliases__, _, _aliases} | _] = ast},
         issues,
         issue_meta
       ) do
    case Macro.prewalk(ast, [], &find_structs_with_32_fields/2) do
      {ast, []} ->
        {ast, issues}

      {ast, structs} ->
        issues =
          Enum.reduce(structs, issues, fn {curr, meta}, acc ->
            [issue_for(issue_meta, meta, curr) | acc]
          end)

        {ast, issues}
    end
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp find_structs_with_32_fields(
         [
           {:__aliases__, meta, aliases},
           [do: {:defstruct, _, [fields]}]
         ],
         acc
       ) do
    if length(fields) >= 32 do
      {[], [{Name.full(aliases), meta} | acc]}
    else
      {[], acc}
    end
  end

  defp find_structs_with_32_fields(ast, acc) do
    {ast, acc}
  end

  defp issue_for(issue_meta, meta, struct) do
    format_issue(issue_meta,
      message: "Struct %#{struct}{} found to have more than 32 fields.",
      trigger: "#{struct} do",
      line_no: meta[:line],
      column: meta[:column]
    )
  end
end
