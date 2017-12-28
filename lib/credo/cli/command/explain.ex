defmodule Credo.CLI.Command.Explain do
  use Credo.CLI.Command

  @shortdoc "Show code object and explain why it is/might be an issue"

  alias Credo.Execution
  alias Credo.CLI.Filename
  alias Credo.CLI.Output.Explain
  alias Credo.CLI.Output.UI

  # TODO: explain used exec options

  @doc false
  def call(%Execution{help: true} = exec, _opts), do: print_help(exec)
  def call(exec, _opts) do
    filename = get_filename(exec)

    if Filename.contains_line_no?(filename) do
      exec
      |> Credo.CLI.Task.LoadAndValidateSourceFiles.call()
      |> Credo.CLI.Task.PrepareChecksToRun.call()
      |> Credo.CLI.Task.RunChecks.call()
      |> print_results_and_summary()
      |> Credo.CLI.Task.SetRelevantIssues.call()
    else
      print_help(exec)
    end
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
