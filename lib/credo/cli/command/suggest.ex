defmodule Credo.CLI.Command.Suggest do
  use Credo.CLI.Command

  @shortdoc "Suggest code objects to look at next (default)"

  alias Credo.Check.Runner
  alias Credo.Config
  alias Credo.CLI.Filter
  alias Credo.CLI.Output.IssuesGroupedByCategory
  alias Credo.CLI.Output.UI
  alias Credo.CLI.Output
  alias Credo.Sources

  def run(_args, %Config{help: true}), do: print_help()
  def run(_args, config) do
    {time_load, source_files} = load_and_validate_source_files(config)

    out = output_mod(config)
    out.print_before_info(source_files, config)

    {time_run, {source_files, config}}  = run_checks(source_files, config)

    print_results_and_summary(source_files, config, time_load, time_run)

    issues =
      source_files
      |> Enum.flat_map(&(&1.issues))
      |> Filter.important(config)
      |> Filter.valid_issues(config)

    case issues do
      [] -> :ok
      issues -> {:error, issues}
    end
  end

  def load_and_validate_source_files(config) do
    {time_load, {valid_source_files, invalid_source_files}} =
      :timer.tc fn ->
        config
        |> Sources.find
        |> Enum.partition(&(&1.valid?))
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

  defp output_mod(%Config{format: "oneline"}) do
    IssuesGroupedByCategory # TODO: offer short list (?)
  end
  defp output_mod(%Config{format: _}) do
    IssuesGroupedByCategory
  end

  defp print_results_and_summary(source_files, config, time_load, time_run) do
    out = output_mod(config)

    source_files
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
          --format          Display the list in a specific format (oneline,flycheck)

    General options:
      -v, --version         Show version
      -h, --help            Show this help
    """
    |> UI.puts
  end
end
