defmodule Credo.Check.Consistency.UnusedVariableNames do
  use Credo.Check,
    run_on_all: true,
    base_priority: :high,
    explanations: [
      check: """
      Elixir allows us to use `_` as a name for variables that are not meant to be
      used. But it’s a common practice to give these variables meaningful names
      anyway (`_user` instead of `_`), but some people prefer to name them all `_`.

      A single style should be present in the same codebase.
      """
    ]

  @collector Credo.Check.Consistency.UnusedVariableNames.Collector

  @doc false
  @impl true
  def run_on_all_source_files(exec, source_files, params) do
    @collector.find_and_append_issues(source_files, exec, params, &issues_for/3)
  end

  defp issues_for(expected, source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)
    issue_locations = @collector.find_locations_not_matching(expected, source_file)

    Enum.map(issue_locations, fn location ->
      format_issue(issue_meta, [
        {:message, message_for(expected, location[:trigger])} | location
      ])
    end)
  end

  defp message_for(:meaningful, trigger) do
    message = """
    Unused variables should be named consistently.
    It seems your strategy is to give them meaningful names (eg. `_foo`)
    but `#{trigger}` does not follow that convention."
    """

    to_one_line(message)
  end

  defp message_for(:anonymous, trigger) do
    message = """
    Unused variables should be named consistently.
    It seems your strategy is to name them anonymously (ie. `_`)
    but `#{trigger}` does not follow that convention.
    """

    to_one_line(message)
  end

  defp to_one_line(str) do
    str
    |> String.split()
    |> Enum.join(" ")
  end
end
