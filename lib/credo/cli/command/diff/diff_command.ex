defmodule Credo.CLI.Command.Diff.DiffCommand do
  @moduledoc false

  use Credo.CLI.Command

  @shortdoc "Suggest code objects to look at next (based on git-diff)"

  alias Credo.CLI.Command.Diff.DiffOutput
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
      print_previous_analysis: [
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

  def git_diff_git_ref_or_range(exec) do
    List.first(exec.cli_options.args) || "HEAD"
  end

  defmodule GetGitDiff do
    use Credo.Execution.Task

    alias Credo.CLI.Command.Diff.DiffCommand
    alias Credo.CLI.Output.Shell

    def call(exec, _opts) do
      case Execution.get_assign(exec, "credo.diff.previous_exec") do
        %Execution{} -> exec
        _ -> run_credo_and_store_resulting_execution(exec)
      end
    end

    def run_credo_and_store_resulting_execution(exec) do
      git_ref_or_range = DiffCommand.git_diff_git_ref_or_range(exec)

      previous_dirname = run_git_clone_and_checkout(exec.cli_options.path, git_ref_or_range)

      git_ref_candidate = List.first(exec.cli_options.args)

      previous_argv =
        case Enum.take(exec.argv, 2) do
          ["diff", ^git_ref_candidate] ->
            [previous_dirname] ++ Enum.slice(exec.argv, 2..-1) ++ ["--strict"]

          ["diff"] ->
            [previous_dirname] ++ Enum.slice(exec.argv, 1..-1) ++ ["--strict"]
        end

      parent_pid = self()

      spawn(fn ->
        Shell.supress_output(fn ->
          previous_exec = Credo.run(previous_argv)

          send(parent_pid, {:previous_exec, previous_exec})
        end)
      end)

      receive do
        {:previous_exec, previous_exec} ->
          Execution.put_assign(exec, "credo.diff.previous_exec", previous_exec)
      end
    end

    defp run_git_clone_and_checkout(path, git_ref) do
      now = DateTime.utc_now() |> to_string |> String.replace(~r/\D/, "")
      dirname = "credo-diff-#{now}"
      tmp_dirname = Path.join(System.tmp_dir!(), dirname)

      {_output, 0} =
        System.cmd("git", ["clone", ".", tmp_dirname], cd: path, stderr_to_stdout: true)

      {_output, 0} =
        System.cmd("git", ["checkout", git_ref], cd: tmp_dirname, stderr_to_stdout: true)

      tmp_dirname
    end
  end

  defmodule FilterIssuesBasedOnFilenames do
    use Credo.Execution.Task

    alias Credo.Issue

    def call(exec, _opts) do
      previous_issues =
        exec
        |> Execution.get_assign("credo.diff.previous_exec")
        |> Execution.get_issues()

      issues =
        exec
        |> Execution.get_issues()
        |> Enum.filter(&new_issue?(&1, previous_issues))

      Execution.set_issues(exec, issues)
    end

    defp new_issue?(issue, previous_issues) when is_list(previous_issues) do
      !Enum.any?(previous_issues, &same_issue?(issue, &1))
    end

    defp same_issue?(current_issue, %Issue{} = previous_issue) do
      # current_issue.filename == previous_issue.filename &&

      current_issue.line_no == previous_issue.line_no &&
        current_issue.column == previous_issue.column &&
        current_issue.category == previous_issue.category &&
        current_issue.message == previous_issue.message &&
        current_issue.trigger == previous_issue.trigger &&
        current_issue.scope == previous_issue.scope
    end
  end

  defmodule PrintBeforeInfo do
    @moduledoc false

    use Credo.Execution.Task

    def call(exec, _opts) do
      source_files = Execution.get_source_files(exec)

      DiffOutput.print_before_info(source_files, exec)

      exec
    end
  end

  defmodule PrintResultsAndSummary do
    @moduledoc false

    use Credo.Execution.Task

    def call(exec, _opts) do
      source_files = Execution.get_source_files(exec)

      time_load = Execution.get_assign(exec, "credo.time.source_files")
      time_run = Execution.get_assign(exec, "credo.time.run_checks")

      DiffOutput.print_after_info(source_files, exec, time_load, time_run)

      exec
    end
  end
end
