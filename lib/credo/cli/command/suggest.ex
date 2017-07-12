defmodule Credo.CLI.Command.Suggest do
  use Credo.CLI.Command

  @shortdoc "Suggest code objects to look at next (default)"

  alias Credo.Check.Runner
  alias Credo.Execution
  alias Credo.CLI.Filter
  alias Credo.CLI.Output.IssuesGroupedByCategory
  alias Credo.CLI.Output.UI
  alias Credo.CLI.Output
  alias Credo.Sources

  @doc false
  def run(%Execution{help: true} = exec), do: print_help(exec)
  def run(exec) do
    exec
    |> load_and_validate_source_files()
    |> Runner.prepare_config
    |> print_before_info()
    |> run_checks()
    |> print_results_and_summary()
    |> determine_success()
  end

  defp load_and_validate_source_files(exec) do
    {time_load, {valid_source_files, invalid_source_files}} =
      :timer.tc fn ->
        exec
        |> Sources.find
        |> Credo.Backports.Enum.split_with(&(&1.valid?))
      end

    Output.complain_about_invalid_source_files(invalid_source_files)

    exec
    |> Execution.put_source_files(valid_source_files)
    |> Execution.put_assign("credo.time.source_files", time_load)
  end

  defp print_before_info(exec) do
    source_files = Execution.get_source_files(exec)

    out = output_mod(exec)
    out.print_before_info(source_files, exec)

    exec
  end

  defp run_checks(%Execution{} = exec) do
    source_files = Execution.get_source_files(exec)

    {time_run, :ok} =
      :timer.tc fn ->
        Runner.run(source_files, exec)
      end

    Execution.put_assign(exec, "credo.time.run_checks", time_run)
  end

  defp print_results_and_summary(%Execution{} = exec) do
    source_files = Execution.get_source_files(exec)

    time_load = Execution.get_assign(exec, "credo.time.source_files")
    time_run = Execution.get_assign(exec, "credo.time.run_checks")
    out = output_mod(exec)

    out.print_after_info(source_files, exec, time_load, time_run)

    exec
  end

  defp determine_success(exec) do
    issues =
      exec
      |> Execution.get_issues
      |> Filter.important(exec)
      |> Filter.valid_issues(exec)

    Execution.put_result(exec, "credo.issues", issues)
  end

  defp output_mod(%Execution{format: "oneline"}) do
    IssuesGroupedByCategory # TODO: offer short list (?)
  end
  defp output_mod(%Execution{format: _}) do
    IssuesGroupedByCategory
  end

  defp print_help(exec) do
    usage = ["Usage: ", :olive, "mix credo suggest [paths] [options]"]
    description =
      """

      Suggests objects from every category that Credo thinks can be improved.
      """
    example = ["Example: ", :olive, :faint, "$ mix credo suggest lib/**/*.ex --all -c names"]
    options =
      """

      Arrows (↑ ↗ → ↘ ↓) hint at the importance of an issue.

      Suggest options:
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
