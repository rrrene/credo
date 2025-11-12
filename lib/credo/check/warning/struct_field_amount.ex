defmodule Credo.Check.Warning.StructFieldAmount do
  @moduledoc false

  use Credo.Check,
    id: "EX5026",
    base_priority: :normal,
    category: :warning,
    param_defaults: [max_fields: 31],
    explanations: [
      check: """
      Avoid structs with 32 or more fields.

      Structs in Elixir are implemented as compile-time maps, which have a
      predefined amount of fields.

      When structs have 32 or more fields, their internal representation in
      the Erlang Virtual Machines changes, potentially leading to bloating
      and higher memory usage.

      https://hexdocs.pm/elixir/1.19.0/code-anti-patterns.html#structs-with-32-fields-or-more
      """,
      params: [
        max_fields: "The maximum number of field a struct should be allowed to have."
      ]
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)
    max_fields = Params.get(params, :max_fields, __MODULE__)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta, max_fields))
  end

  defp traverse({:defstruct, meta, [fields]} = ast, issues, issue_meta, max_fields) do
    if length(fields) > max_fields do
      {ast, [issue_for(issue_meta, meta, max_fields) | issues]}
    else
      {ast, issues}
    end
  end

  defp traverse(ast, issues, _issue_meta, _max_fields) do
    {ast, issues}
  end

  defp issue_for(issue_meta, meta, max_fields) do
    format_issue(issue_meta,
      message: "Struct has more than #{max_fields} fields.",
      trigger: "defstruct",
      line_no: meta[:line],
      column: meta[:column]
    )
  end
end
