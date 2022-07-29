defmodule Credo.CLI.Command.Explain.ExplainCommand do
  @moduledoc false

  use Credo.CLI.Command,
    short_description: "Show code object and explain why it is/might be an issue",
    cli_switches: Credo.CLI.Command.Suggest.SuggestCommand.cli_switches()

  alias Credo.Check
  alias Credo.CLI.Command.Explain.ExplainOutput, as: Output
  alias Credo.CLI.Filename
  alias Credo.CLI.Task
  alias Credo.Execution
  alias Credo.Issue
  alias Credo.SourceFile

  def init(exec) do
    exec
    |> Execution.put_pipeline(__MODULE__.ExplainIssue,
      validate_given_location: [
        {__MODULE__.ExplainIssuePreCheck, []}
      ],
      load_and_validate_source_files: [
        {Task.LoadAndValidateSourceFiles, []}
      ],
      prepare_analysis: [
        {Task.PrepareChecksToRun, []}
      ],
      run_analysis: [
        {Task.RunChecks, []}
      ],
      filter_issues: [
        {Task.SetRelevantIssues, []}
      ],
      print_explanation: [
        {__MODULE__.ExplainIssue, []}
      ]
    )
    |> Execution.put_pipeline(__MODULE__.ExplainCheck,
      print_explanation: [
        {__MODULE__.ExplainCheck, []}
      ]
    )
  end

  @doc false
  def call(%Execution{help: true} = exec, _opts), do: Output.print_help(exec)

  def call(exec, _opts) do
    filename = get_filename_from_args(exec)

    cond do
      Filename.contains_line_no?(filename) ->
        Execution.run_pipeline(exec, __MODULE__.ExplainIssue)

      Check.defined?("Elixir.#{filename}") ->
        Execution.run_pipeline(exec, __MODULE__.ExplainCheck)

      true ->
        Output.print_help(exec)
    end
  end

  @doc false
  def get_filename_from_args(exec) do
    exec.cli_options.args
    |> List.wrap()
    |> List.first()
  end

  defmodule ExplainCheck do
    use Credo.Execution.Task

    alias Credo.CLI.Command.Explain.ExplainCommand

    def call(exec, _opts) do
      check_name = ExplainCommand.get_filename_from_args(exec)
      check = :"Elixir.#{check_name}"
      explanations = [cast_to_explanation(check)]

      Output.print_after_info(explanations, exec, nil, nil)

      exec
    end

    defp cast_to_explanation(check) do
      %{
        category: check.category,
        check: check,
        explanation_for_issue: check.explanation,
        priority: check.base_priority
      }
    end
  end

  defmodule ExplainIssuePreCheck do
    use Credo.Execution.Task

    alias Credo.CLI.Command.Explain.ExplainCommand

    def call(exec, _opts) do
      filename_with_location = ExplainCommand.get_filename_from_args(exec)
      working_dir = Execution.working_dir(exec)

      filename =
        filename_with_location
        |> String.split(":")
        |> List.first()
        |> Path.expand()

      if path_contains_file?(working_dir, filename) do
        exec
      else
        Execution.halt(exec, """
        Given location is not part of the working dir.

          Location:     #{filename_with_location}
          Working dir:  #{working_dir}
        """)
      end
    end

    # def error(exec, _opts) do
    #   halt_message = Execution.get_halt_message(exec)

    #   UI.warn([:red, "** (explain) ", halt_message])

    #   exec
    # end

    defp path_contains_file?(path, filename) do
      case Path.relative_to(filename, path) do
        ^filename -> false
        _ -> true
      end
    end
  end

  defmodule ExplainIssue do
    use Credo.Execution.Task

    alias Credo.CLI.Command.Explain.ExplainCommand

    def call(exec, _opts) do
      filename = ExplainCommand.get_filename_from_args(exec)

      source_files = Execution.get_source_files(exec)

      filename
      |> String.split(":")
      |> print_result(source_files, exec)
    end

    def print_result([filename], source_files, exec) do
      print_result([filename, nil, nil], source_files, exec)
    end

    def print_result([filename, line_no], source_files, exec) do
      print_result([filename, line_no, nil], source_files, exec)
    end

    def print_result([filename, line_no, column], source_files, exec) do
      source_file = Enum.find(source_files, &(&1.filename == filename))

      if source_file do
        explanations =
          exec
          |> Execution.get_issues(source_file.filename)
          |> filter_issues(line_no, column)
          |> Enum.map(&cast_to_explanation(&1, source_file))

        Output.print_after_info(explanations, exec, line_no, column)

        exec
      else
        Execution.halt(exec, "Could not find source file: #{filename}")
      end
    end

    defp cast_to_explanation(issue, source_file) do
      %{
        category: issue.category,
        check: issue.check,
        column: issue.column,
        explanation_for_issue: issue.check.explanation,
        filename: issue.filename,
        line_no: issue.line_no,
        message: issue.message,
        priority: issue.priority,
        related_code: find_related_code(source_file, issue.line_no),
        scope: issue.scope,
        trigger: issue.trigger
      }
    end

    defp find_related_code(source_file, line_no) do
      [
        get_source_line(source_file, line_no - 2),
        get_source_line(source_file, line_no - 1),
        get_source_line(source_file, line_no),
        get_source_line(source_file, line_no + 1),
        get_source_line(source_file, line_no + 2)
      ]
      |> Enum.reject(&is_nil/1)
    end

    defp get_source_line(_, line_no) when line_no < 1 do
      nil
    end

    defp get_source_line(source_file, line_no) do
      line = SourceFile.line_at(source_file, line_no)

      if line do
        {line_no, line}
      end
    end

    defp filter_issues(issues, line_no, nil) do
      line_no = line_no |> String.to_integer()
      issues |> Enum.filter(&filter_issue(&1, line_no, nil))
    end

    defp filter_issues(issues, line_no, column) do
      line_no = line_no |> String.to_integer()
      column = column |> String.to_integer()

      issues |> Enum.filter(&filter_issue(&1, line_no, column))
    end

    defp filter_issue(%Issue{line_no: a, column: b}, a, b), do: true
    defp filter_issue(%Issue{line_no: a}, a, _), do: true
    defp filter_issue(_, _, _), do: false
  end
end
