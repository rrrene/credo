defmodule Credo.CLI.Command.Explain do
  use Credo.CLI.Command

  @shortdoc "Show code object and explain why it is/might be an issue"

  alias Credo.Check.Runner
  alias Credo.Execution
  alias Credo.CLI.Filename
  alias Credo.CLI.Output.Explain
  alias Credo.CLI.Output.UI
  alias Credo.CLI.Output
  alias Credo.Sources

  # TODO: explain used exec options

  @doc false
  def run(%Execution{help: true} = exec), do: print_help(exec)
  def run(exec) do
    filename = get_filename(exec)

    if Filename.contains_line_no?(filename) do
      exec
      |> load_and_validate_source_files()
      |> Runner.prepare_config
      |> run_checks()
      |> print_results_and_summary()
      |> determine_success()
    else
      print_help(exec)
    end
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

  defp run_checks(%Execution{} = exec) do
    source_files = Execution.get_source_files(exec)

    {time_run, :ok} =
      :timer.tc fn ->
        Runner.run(source_files, exec)
      end

    exec
    |> Execution.put_assign("credo.time.run_checks", time_run)
  end

  defp print_results_and_summary(exec) do
    filename = get_filename(exec)

    source_files = Execution.get_source_files(exec)

    filename
    |> String.split(":")
    |> print_result(source_files, exec)

    exec
  end

  defp get_filename(exec) do
    exec.cli_options.args
    |> List.wrap
    |> List.first
  end

  defp determine_success(exec) do
    exec
  end

  defp output_mod(_) do
    Explain
  end

  defp print_result([filename], source_files, exec) do
    print_result([filename, nil, nil], source_files, exec)
  end
  defp print_result([filename, line_no], source_files, exec) do
    print_result([filename, line_no, nil], source_files, exec)
  end
  defp print_result([filename, line_no, column], source_files, exec) do
    source_files
    |> Enum.find(&(&1.filename == filename))
    |> print_result(exec, line_no, column)
  end

  def print_result(source_file, exec, line_no, column) do
    output = output_mod(exec)
    output.print_before_info([source_file], exec)

    output.print_after_info(source_file, exec, line_no, column)
  end

  defp print_help(exec) do
    usage = ["Usage: ", :olive, "mix credo explain path_line_no_column [options]"]
    description =
      """

      Explain the given issue.
      """
    example = ["Example: ", :olive, :faint, "$ mix credo explain lib/foo/bar.ex:13:6"]
    options =
      """

      General options:
        -v, --version       Show version
        -h, --help          Show this help
      """

    UI.puts(usage)
    UI.puts(description)
    UI.puts(example)
    UI.puts(options)

    exec
  end
end
