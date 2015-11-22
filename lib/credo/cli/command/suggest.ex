defmodule Credo.CLI.Command.Suggest do
  @shortdoc "Suggest code objects to look at next (default)"

  alias Credo.Check.Runner
  alias Credo.Config
  alias Credo.CLI.Filter
  alias Credo.CLI.Output.IssuesGroupedByCategory
  alias Credo.CLI.Output.UI
  alias Credo.CLI.Output
  alias Credo.Sources

  def run(_dir, %Config{help: true}), do: print_help
  def run(_dir, config) do
    {time_load, source_files} = load_and_validate_source_files(config)

    out = output_mod(config)
    out.print_before_info(source_files)

    {time_run, source_files}  = run_checks(source_files, config)

    print_results_and_summary(source_files, config, time_load, time_run)

    # TODO: return :error if there are issues so the CLI can exit with a status
    #       code other than zero
    :ok
  end

  def load_and_validate_source_files(config) do
    {time_load, {valid_source_files, invalid_source_files}} =
      :timer.tc fn ->
        source_files = config |> Sources.find
        valid_source_files = Enum.filter(source_files, &(&1.valid?))
        invalid_source_files = Enum.filter(source_files, &(!&1.valid?))

        {valid_source_files, invalid_source_files}
      end

    invalid_source_files
    |> Output.complain_about_invalid_source_files

    {time_load, valid_source_files}
  end

  def run_checks(source_files, config) do
    :timer.tc fn ->
      Runner.run(source_files, config)
    end
  end

  defp output_mod(%Config{one_line: true}) do
    IssuesGroupedByCategory # TODO: offer short list (?)
  end
  defp output_mod(%Config{one_line: false}) do
    IssuesGroupedByCategory
  end

  defp print_results_and_summary(source_files, config, time_load, time_run) do
    out = output_mod(config)

    source_files
    |> Filter.important(config)
    |> out.print_after_info(config, time_load, time_run)
  end

  defp print_help do
    ["Usage: ", :olive, "mix credo suggest [paths] [options]"]
    |> UI.puts
    """

    Suggests objects from every category that Credo thinks can be improved.
    """
    |> UI.puts
    ["Example: ", :olive, :faint, "$ mix credo suggest lib/**/*.ex --all -c names"]
    |> UI.puts
    """

    Arrows (↑ ↗ → ↘ ↓) hint at the importance of an issue.

    Suggest options:
      -a, --all             Show all issues
      -A, --all-priorities  Show all issues including low priority ones
      -c, --checks          Only include checks that match the given strings
      -C, --config-name     Use the given config instead of "default"
      -i, --ignore-checks   Ignore checks that match the given strings
          --one-line        Show a condensed version of the list
          --verbose         Show a verbose version with code snippets

    General options:
      -v, --version         Show version
      -h, --help            Show this help
    """
    |> UI.puts
  end
end
