defmodule Credo.CLI.Command.Explain do
  use Credo.CLI.Command

  @shortdoc "Show code object and explain why it is/might be an issue"

  alias Credo.Check.Runner
  alias Credo.Config
  alias Credo.CLI.Output.Explain
  alias Credo.CLI.Output.UI
  alias Credo.CLI.Output
  alias Credo.Sources

  # TODO: explain used config options

  def run(_args, %Config{help: true}), do: print_help()
  def run([], _), do: print_help()
  def run([file | _], config) do
    {_, source_files} = load_and_validate_source_files(config)
    {_, {source_files, config}}  = run_checks(source_files, config)

    file
    |> String.split(":")
    |> print_result(source_files, config)

    # TODO: return :error if there are issues so the CLI can exit with a status
    #       code other than zero
    :ok
  end

  defp load_and_validate_source_files(config) do
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

  defp run_checks(source_files, config) do
    :timer.tc fn ->
      Runner.run(source_files, config)
    end
  end

  defp output_mod(_) do
    Explain
  end

  defp print_result([filename], source_files, config) do
    print_result([filename, nil, nil], source_files, config)
  end
  defp print_result([filename, line_no], source_files, config) do
    print_result([filename, line_no, nil], source_files, config)
  end
  defp print_result([filename, line_no, column], source_files, config) do
    source_files
    |> Enum.find(&(&1.filename == filename))
    |> print_result(config, line_no, column)
  end

  def print_result(source_file, config, line_no, column) do
    output = output_mod(config)
    output.print_before_info([source_file], config)

    source_file
    |> output.print_after_info(config, line_no, column)
  end


  defp print_help do
    ["Usage: ", :olive, "mix credo explain path_line_no_column [options]"]
    |> UI.puts
    """

    Explain the given issue.
    """
    |> UI.puts
    ["Example: ", :olive, :faint, "$ mix credo explain lib/foo/bar.ex:13:6"]
    |> UI.puts
    """

    General options:
      -v, --version       Show version
      -h, --help          Show this help
    """
    |> UI.puts
  end
end
