defmodule Credo.CLI.Command.Diff.DiffCommand do
  @moduledoc false

  use Credo.CLI.Command

  @shortdoc "Suggest code objects to look at next (based on git-diff)"

  alias Credo.CLI.Command.Diff.DiffOutput
  alias Credo.CLI.Command.Suggest.SuggestOutput
  alias Credo.CLI.Task
  alias Credo.Execution

  def init(exec) do
    exec
    |> Execution.put_pipeline(__MODULE__,
      load_and_validate_source_files: [
        {Task.LoadAndValidateSourceFiles, []}
      ],
      prepare_analysis: [
        {Task.PrepareChecksToRun, []}
      ],
      print_before_analysis: [
        {__MODULE__.GetGitDiff, []},
        {__MODULE__.PrintBeforeInfo, []}
      ],
      run_analysis: [
        {Task.RunChecks, []}
      ],
      filter_issues: [
        {Task.SetRelevantIssues, []},
        {__MODULE__.FilterIssuesBasedOnFilenames, []}
      ],
      print_after_analysis: [
        {__MODULE__.PrintResultsAndSummary, []}
      ]
    )
  end

  def call(%Execution{help: true} = exec, _opts), do: DiffOutput.print_help(exec)
  def call(exec, _opts), do: Execution.run_pipeline(exec, __MODULE__)

  def git_diff_commits(exec) do
    exec.diff_with || "HEAD"
  end

  defmodule GetGitDiff do
    use Credo.Execution.Task

    alias Credo.CLI.Command.Diff.DiffCommand

    def call(exec, _opts) do
      commits = DiffCommand.git_diff_commits(exec)
      output = run_git_diff(exec.cli_options.path, commits)
      filenames = String.split(output, "\n")

      Execution.put_assign(exec, "credo.diff.filenames", filenames)
    end

    defp run_git_diff(path, commits_or_commit_range) do
      {output, 0} = System.cmd("git", ["diff", commits_or_commit_range, "--name-only"], cd: path)

      String.trim(output)
    end
  end

  defmodule FilterIssuesBasedOnFilenames do
    use Credo.Execution.Task

    def call(exec, _opts) do
      filenames = Execution.get_assign(exec, "credo.diff.filenames")

      issues =
        exec
        |> Execution.get_issues()
        |> Enum.filter(&Enum.member?(filenames, &1.filename))

      Execution.set_issues(exec, issues)
    end
  end

  defmodule PrintBeforeInfo do
    use Credo.Execution.Task

    alias Credo.CLI.Command.Diff.DiffCommand
    alias Credo.CLI.Output.UI

    def call(exec, _opts) do
      source_files = Execution.get_source_files(exec)

      SuggestOutput.print_before_info(source_files, exec)
      print_diff_file_count(exec)

      exec
    end

    # TODO: is this the canonical way to include the "default" format?
    defp print_diff_file_count(%Execution{format: nil} = exec) do
      commits = DiffCommand.git_diff_commits(exec)
      filenames_count = exec |> Execution.get_assign("credo.diff.filenames") |> Enum.count()

      file_label =
        if filenames_count == 1 do
          "1 file"
        else
          "#{filenames_count} files"
        end

      UI.puts([:faint, "Considering #{file_label} (diffing with `#{commits}`) ..."])
    end

    defp print_diff_file_count(_exec), do: nil
  end

  defmodule PrintResultsAndSummary do
    @moduledoc false

    use Credo.Execution.Task

    def call(exec, _opts) do
      source_files = Execution.get_source_files(exec)

      time_load = Execution.get_assign(exec, "credo.time.source_files")
      time_run = Execution.get_assign(exec, "credo.time.run_checks")

      SuggestOutput.print_after_info(source_files, exec, time_load, time_run)

      exec
    end
  end
end
