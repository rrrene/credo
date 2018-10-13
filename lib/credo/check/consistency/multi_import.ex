defmodule Credo.Check.Consistency.MultiImport do
  @moduledoc """
  When using alias, import, require or use for multiple names from the same
  namespace, you have two options:

  Use single instructions per name:

    import Ecto.Query
    import Ecto.Schema
    import Ecto.Multi

  or use one multi instruction per namespace:

    import Ecto.{Query, Schema, Multi}

  While this is not necessarily a concern for the correctness of your code,
  you should use a consistent style throughout your codebase.
  """

  @explanation [check: @moduledoc]

  @collector Credo.Check.Consistency.MultiImport.Collector

  use Credo.Check, run_on_all: true, base_priority: :high

  @doc false
  def run(source_files, exec, params \\ []) when is_list(source_files) do
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
    "Most of the time you are using the multi-import, but here you are using multiple single directives"
  end

  defp message_for(:single = _expected) do
    "Most of the time you are using the multiple single line import but here you are using the multi-import syntax"
  end
end
