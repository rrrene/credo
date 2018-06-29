defmodule Credo.CLI.Command.Explain.ExplainCommand do
  use Credo.CLI.Command

  @shortdoc "Show code object and explain why it is/might be an issue"
  @moduledoc @shortdoc

  alias Credo.Execution
  alias Credo.CLI.Command.Explain.ExplainOutput, as: Output
  alias Credo.CLI.Filename
  alias Credo.CLI.Task

  @doc false
  def call(%Execution{help: true} = exec, _opts), do: Output.print_help(exec)

  def call(exec, _opts) do
    filename = get_filename_from_args(exec)

    if Filename.contains_line_no?(filename) do
      exec
      |> run_task(Task.LoadAndValidateSourceFiles)
      |> run_task(Task.PrepareChecksToRun)
      |> run_task(Task.RunChecks)
      |> run_task(Task.SetRelevantIssues)
      |> print_results_and_summary()
    else
      Output.print_help(exec)
    end
  end

  defp print_results_and_summary(exec) do
    filename = get_filename_from_args(exec)

    source_files = Execution.get_source_files(exec)

    filename
    |> String.split(":")
    |> print_result(source_files, exec)

    exec
  end

  def print_result([filename], source_files, exec) do
    print_result([filename, nil, nil], source_files, exec)
  end

  def print_result([filename, line_no], source_files, exec) do
    print_result([filename, line_no, nil], source_files, exec)
  end

  def print_result([filename, line_no, column], source_files, exec) do
    source_files
    |> Enum.find(&(&1.filename == filename))
    |> print_result(exec, line_no, column)
  end

  def print_result(source_file, exec, line_no, column) do
    Output.print_before_info([source_file], exec)

    Output.print_after_info(source_file, exec, line_no, column)
  end

  defp get_filename_from_args(exec) do
    exec.cli_options.args
    |> List.wrap()
    |> List.first()
  end
end
