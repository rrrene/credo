defmodule Credo.CLI.Command.List do
  use Credo.CLI.Command

  @shortdoc "List all issues grouped by files"

  alias Credo.Execution
  alias Credo.CLI.Output.IssuesByScope
  alias Credo.CLI.Output.IssuesShortList
  alias Credo.CLI.Output.UI

  @doc false
  def call(%Execution{help: true} = exec, _opts), do: print_help(exec)
  def call(exec, _opts) do
    exec
    |> Credo.CLI.Task.LoadAndValidateSourceFiles.call()
    |> Credo.CLI.Task.PrepareChecksToRun.call()
    |> print_before_info()
    |> Credo.CLI.Task.RunChecks.call()
    |> print_results_and_summary()
    |> Credo.CLI.Task.SetRelevantIssues.call()
  end

  defp print_before_info(exec) do
    source_files = Execution.get_source_files(exec)

    out = output_mod(exec)
    out.print_before_info(source_files, exec)

    exec
  end

  defp print_results_and_summary(%Execution{} = exec) do
    source_files = Execution.get_source_files(exec)

    time_load = Execution.get_assign(exec, "credo.time.source_files")
    time_run = Execution.get_assign(exec, "credo.time.run_checks")
    out = output_mod(exec)

    out.print_after_info(source_files, exec, time_load, time_run)

    exec
  end

  defp output_mod(%Execution{format: "oneline"}) do
    IssuesShortList
  end
  defp output_mod(%Execution{format: _}) do
    IssuesByScope
  end


  defp print_help(exec) do
    usage = ["Usage: ", :olive, "mix credo list [paths] [options]"]
    description =
      """

      Lists objects that Credo thinks can be improved ordered by their priority.
      """
    example = ["Example: ", :olive, :faint, "$ mix credo list lib/**/*.ex --format=oneline"]
    options =
      """

      Arrows (↑ ↗ → ↘ ↓) hint at the importance of an issue.

      List options:
        -a, --all             Show all issues
        -A, --all-priorities  Show all issues including low priority ones
        -c, --checks          Only include checks that match the given strings
        -C, --config-name     Use the given config instead of "default"
        -i, --ignore-checks   Ignore checks that match the given strings
            --format          Display the list in a specific format (oneline,flycheck)

      General options:
        -v, --version         Show version
        -h, --help            Show this help
      """

    UI.puts(usage)
    UI.puts(description)
    UI.puts(example)
    UI.puts(options)

    exec
  end
end
