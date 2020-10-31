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
        {__MODULE__.FilterIssues, []}
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
      previous_git_ref = DiffCommand.git_diff_git_ref_or_range(exec)

      previous_dirname = run_git_clone_and_checkout(exec.cli_options.path, previous_git_ref)

      previous_argv =
        case Enum.take(exec.argv, 2) do
          ["diff", ^previous_git_ref] ->
            [previous_dirname] ++ Enum.slice(exec.argv, 2..-1) ++ ["--strict"]

          ["diff", _] ->
            [previous_dirname] ++ Enum.slice(exec.argv, 1..-1) ++ ["--strict"]

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
          exec
          |> Execution.put_assign("credo.diff.previous_git_ref", previous_git_ref)
          |> Execution.put_assign("credo.diff.previous_dirname", previous_dirname)
          |> Execution.put_assign("credo.diff.previous_exec", previous_exec)
      end
    end

    defp run_git_clone_and_checkout(path, git_ref) do
      now = DateTime.utc_now() |> to_string |> String.replace(~r/\D/, "")
      tmp_clone_dir = Path.join(System.tmp_dir!(), "credo-diff-#{now}")
      git_root_path = git_root_path(path)
      current_dir = Path.expand(".")
      tmp_working_dir = tmp_working_dir(tmp_clone_dir, git_root_path, current_dir)

      {_output, 0} =
        System.cmd("git", ["clone", git_root_path, tmp_clone_dir],
          cd: path,
          stderr_to_stdout: true
        )

      {_output, 0} =
        System.cmd("git", ["checkout", git_ref], cd: tmp_clone_dir, stderr_to_stdout: true)

      tmp_working_dir
    end

    defp git_root_path(path) do
      {output, 0} =
        System.cmd("git", ["rev-parse", "--show-toplevel"], cd: path, stderr_to_stdout: true)

      String.trim(output)
    end

    defp tmp_working_dir(tmp_clone_dir, git_root_is_current_dir, git_root_is_current_dir) do
      tmp_clone_dir
    end

    defp tmp_working_dir(tmp_clone_dir, git_root_path, current_dir) do
      subdir_to_run_credo_in = Path.relative_to(current_dir, git_root_path)

      Path.join(tmp_clone_dir, subdir_to_run_credo_in)
    end
  end

  defmodule FilterIssues do
    use Credo.Execution.Task

    alias Credo.Issue

    def call(exec, _opts) do
      issues = get_old_new_and_fixed_issues(exec)

      Execution.set_issues(exec, issues)
    end

    defp get_old_new_and_fixed_issues(exec) do
      current_issues = Execution.get_issues(exec)

      previous_issues =
        exec
        |> Execution.get_assign("credo.diff.previous_exec")
        |> Execution.get_issues()

      # in previous_issues, in current_issues
      old_issues = Enum.filter(previous_issues, &old_issue?(&1, current_issues))

      # in previous_issues, not in current_issues
      fixed_issues = previous_issues -- old_issues

      # not in previous_issues, in current_issues
      new_issues = Enum.filter(current_issues, &new_issue?(&1, previous_issues))

      old_issues = Enum.map(old_issues, fn issue -> %Issue{issue | diff_marker: :old} end)

      # TODO: we have to rewrite the filename to make it look like the file is in the current dir instead of the generated tmp dir
      fixed_issues = Enum.map(fixed_issues, fn issue -> %Issue{issue | diff_marker: :fixed} end)
      new_issues = Enum.map(new_issues, fn issue -> %Issue{issue | diff_marker: :new} end)

      List.flatten([fixed_issues, old_issues, new_issues])
    end

    defp new_issue?(current_issue, previous_issues) when is_list(previous_issues) do
      !Enum.any?(previous_issues, &same_issue?(current_issue, &1))
    end

    defp old_issue?(previous_issue, current_issues) when is_list(current_issues) do
      Enum.any?(current_issues, &same_issue?(previous_issue, &1))
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
