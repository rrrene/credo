defmodule Credo.Check.Consistency.ModuleAttributeOrder do
  @moduledoc """
  List module attributes and directives in the following order:

  1.  @moduledoc
  2.  @behaviour
  3.  use
  4.  import
  5.  alias
  6.  require
  7.  defstruct
  8.  @type
  9.  @module_attribute
  10. @callback
  11. @macrocallback
  12. @optional_callbacks

  Like all `Readability` issues, this one is not a technical concern.
  But you can improve the odds of others reading and liking your code by making
  it easier to follow.
  """

  @collector Credo.Check.Consistency.ModuleAttributeOrder.Collector
  @explanation [check: @moduledoc]
  @message "Most of the time you are ordering your module attributes, but here the order is not maintained"

  use Credo.Check, run_on_all: true, base_priority: :low

  @doc false
  def run(source_files, exec, params \\ []) when is_list(source_files) do
    @collector.find_and_append_issues(source_files, exec, params, &issues_for/3)
  end

  defp issues_for(source_file, exec, params) do
    issue_meta = IssueMeta.for(source_file, params)

    source_file
    |> @collector.find_locations_not_matching(exec)
    |> Enum.map(&format_issue(issue_meta, message: @message, line_no: &1))
  end
end
