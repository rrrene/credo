defmodule Credo.Check.Consistency.MultiAliasImportRequireUse do
  use Credo.Check,
    run_on_all: true,
    base_priority: :high,
    tags: [:controversial],
    explanations: [
      check: """
      When using alias, import, require or use for multiple names from the same
      namespace, you have two options:

      Use single instructions per name:

          alias Ecto.Query
          alias Ecto.Schema
          alias Ecto.Multi

      or use one multi instruction per namespace:

          alias Ecto.{Query, Schema, Multi}

      While this is not necessarily a concern for the correctness of your code,
      you should use a consistent style throughout your codebase.
      """
    ]

  @collector Credo.Check.Consistency.MultiAliasImportRequireUse.Collector

  @doc false
  @impl true
  def run_on_all_source_files(exec, source_files, params) do
    @collector.find_and_append_issues(source_files, exec, params, &issues_for/3)
  end

  defp issues_for(expected, source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    issue_locations = @collector.find_locations_not_matching(expected, source_file)

    Enum.map(issue_locations, fn line_no ->
      format_issue(issue_meta, message: message_for(expected), line_no: line_no)
    end)
  end

  defp message_for(:multi = _expected) do
    "Most of the time you are using the multi-alias/require/import/use syntax, but here you are using multiple single directives"
  end

  defp message_for(:single = _expected) do
    "Most of the time you are using the multiple single line alias/require/import/use directives but here you are using the multi-alias/require/import/use syntax"
  end
end
