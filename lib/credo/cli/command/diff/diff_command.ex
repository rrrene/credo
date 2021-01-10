defmodule Credo.CLI.Command.Diff.DiffCommand do
  @moduledoc false

  use Credo.CLI.Command

  @shortdoc "Suggest code objects to look at next (based on git-diff)"

  alias Credo.CLI.Command.Diff.DiffOutput
  alias Credo.CLI.Output.UI
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
      ],
      filter_issues_for_exit_status: [
        {__MODULE__.FilterIssuesForExitStatus, []}
      ]
    )
  end

  def call(%Execution{help: true} = exec, _opts), do: DiffOutput.print_help(exec)
  def call(exec, _opts), do: Execution.run_pipeline(exec, __MODULE__)

  def previous_ref(exec) do
    given_first_arg = List.first(exec.cli_options.args)

    previous_ref_as_git_ref(given_first_arg) ||
      previous_ref_as_path(given_first_arg) ||
      {:error, "given ref is not a Git ref or local path: #{given_first_arg}"}
  end

  def previous_ref_as_git_ref(given_first_arg) do
    if git_present?() do
      potential_git_ref = given_first_arg || "HEAD"

      if git_ref_exists?(potential_git_ref) do
        {:git, potential_git_ref}
      end
    end
  end

  def previous_ref_as_path(potential_path) do
    if File.exists?(potential_path) do
      {:path, potential_path}
    end
  end

  defp git_present?() do
    case System.cmd("git", ["--help"], stderr_to_stdout: true) do
      {_output, 0} -> true
      {_output, _} -> false
    end
  rescue
    _ -> false
  end

  defp git_ref_exists?(git_ref) do
    case System.cmd("git", ["show", git_ref], stderr_to_stdout: true) do
      {_output, 0} -> true
      {_output, _} -> false
    end
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

    def error(exec, _opts) do
      exec
      |> Execution.get_halt_message()
      |> puts_error_message()

      exec
    end

    defp puts_error_message(halt_message) do
      UI.warn([:red, "** (diff) ", halt_message])
      UI.warn("")
    end

    def run_credo_and_store_resulting_execution(exec) do
      case DiffCommand.previous_ref(exec) do
        {:git, git_ref} -> run_credo_on_git_ref(exec, git_ref)
        {:path, path} -> run_credo_on_path_ref(exec, path)
        {:error, error} -> Execution.halt(exec, error)
      end
    end

    def run_credo_on_git_ref(exec, git_ref) do
      previous_dirname = run_git_clone_and_checkout(exec.cli_options.path, git_ref)

      run_credo_on_dir(exec, previous_dirname, git_ref)
    end

    def run_credo_on_path_ref(exec, path) do
      run_credo_on_dir(exec, path, path)
    end

    def run_credo_on_dir(exec, dirname, previous_git_ref) do
      previous_argv =
        case Enum.take(exec.argv, 2) do
          ["diff", ^previous_git_ref] ->
            [dirname] ++ Enum.slice(exec.argv, 2..-1)

          ["diff", _] ->
            [dirname] ++ Enum.slice(exec.argv, 1..-1)

          ["diff"] ->
            [dirname] ++ Enum.slice(exec.argv, 1..-1)
        end

      run_credo(exec, previous_git_ref, dirname, previous_argv)
    end

    def run_credo(exec, previous_git_ref, previous_dirname, previous_argv) do
      parent_pid = self()

      spawn(fn ->
        Shell.supress_output(fn ->
          previous_exec = Credo.run(previous_argv)

          send(parent_pid, {:previous_exec, previous_exec})
        end)
      end)

      receive do
        {:previous_exec, previous_exec} ->
          store_resulting_execution(exec, previous_git_ref, previous_dirname, previous_exec)
      end
    end

    defp store_resulting_execution(exec, previous_git_ref, previous_dirname, previous_exec) do
      if previous_exec.halted do
        halt_execution(exec, previous_git_ref, previous_dirname, previous_exec)
      else
        exec
        |> Execution.put_assign("credo.diff.previous_git_ref", previous_git_ref)
        |> Execution.put_assign("credo.diff.previous_dirname", previous_dirname)
        |> Execution.put_assign("credo.diff.previous_exec", previous_exec)
      end
    end

    defp halt_execution(exec, previous_git_ref, previous_dirname, previous_exec) do
      message =
        case Execution.get_halt_message(previous_exec) do
          {:config_name_not_found, message} -> message
          halt_message -> inspect(halt_message)
        end

      Execution.halt(
        exec,
        [
          :bright,
          "Running Credo on `#{previous_git_ref}` (checked out to #{previous_dirname}) resulted in the following error:\n\n",
          :faint,
          message
        ]
      )
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

  defmodule FilterIssuesForExitStatus do
    @moduledoc false

    use Credo.Execution.Task

    def call(exec, _opts) do
      issues =
        exec
        |> Execution.get_issues()
        |> Enum.filter(fn
          %Credo.Issue{diff_marker: :new} -> true
          _ -> false
        end)

      Execution.set_issues(exec, issues)
    end
  end
end
