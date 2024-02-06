defmodule Credo.CLI.Command.Diff.DiffCommand do
  @moduledoc false

  alias Credo.CLI.Command.Diff.DiffOutput
  alias Credo.CLI.Switch
  alias Credo.CLI.Task
  alias Credo.Execution

  alias Credo.CLI.Command.Diff.Task.FilterIssues
  alias Credo.CLI.Command.Diff.Task.FilterIssuesForExitStatus
  alias Credo.CLI.Command.Diff.Task.GetGitDiff
  alias Credo.CLI.Command.Diff.Task.PrintBeforeInfo
  alias Credo.CLI.Command.Diff.Task.PrintResultsAndSummary

  use Credo.CLI.Command,
    short_description: "Suggest code objects to look at next (based on git-diff)",
    cli_switches:
      Credo.CLI.Command.Suggest.SuggestCommand.cli_switches() ++
        [
          Switch.string("from_dir"),
          Switch.string("from_git_ref"),
          Switch.string("from_git_merge_base"),
          Switch.boolean("show_fixed"),
          Switch.boolean("show_kept"),
          Switch.string("since")
        ]

  def init(exec) do
    Execution.put_pipeline(exec, "diff",
      load_and_validate_source_files: [
        {Task.LoadAndValidateSourceFiles, []}
      ],
      prepare_analysis: [
        {Task.PrepareChecksToRun, []}
      ],
      print_previous_analysis: [
        {GetGitDiff, []},
        {PrintBeforeInfo, []}
      ],
      run_analysis: [
        {Task.RunChecks, []}
      ],
      filter_issues: [
        {Task.SetRelevantIssues, []},
        {FilterIssues, []}
      ],
      print_after_analysis: [
        {PrintResultsAndSummary, []}
      ],
      filter_issues_for_exit_status: [
        {FilterIssuesForExitStatus, []}
      ]
    )
  end

  def call(%Execution{help: true} = exec, _opts), do: DiffOutput.print_help(exec)
  def call(exec, _opts), do: Execution.run_pipeline(exec, __MODULE__)

  def previous_ref(exec) do
    case exec.cli_options.switches do
      %{since: given_datetime} ->
        previous_ref_as_datetime(given_datetime) ||
          {:error, "given value is not a valid commit date: #{given_datetime}"}

      %{from_dir: given_dir} ->
        previous_ref_as_path(given_dir) ||
          {:error, "given value is not a local directory: #{given_dir}"}

      %{from_git_ref: given_git_ref} ->
        previous_ref_as_git_ref(given_git_ref) ||
          {:error, "given value is not a Git ref: #{given_git_ref}"}

      %{from_git_merge_base: given_git_merge_base} ->
        previous_ref_as_git_merge_base(given_git_merge_base) ||
          {:error, "given value is not a Git ref: #{given_git_merge_base}"}

      _ ->
        given_first_arg = List.first(exec.cli_options.args)

        previous_ref_from_first_arg(given_first_arg) ||
          {:error, "given ref is not a Git ref or local path: #{given_first_arg}"}
    end
  end

  defp previous_ref_from_first_arg(nil) do
    previous_ref_as_git_ref("HEAD")
  end

  defp previous_ref_from_first_arg(given_first_arg) do
    previous_ref_as_git_ref(given_first_arg) ||
      previous_ref_as_path(given_first_arg)
  end

  def previous_ref_as_datetime(potential_datetime) do
    if git_present?() do
      {:git_datetime, potential_datetime}
    else
      {:error, "could not run `git`"}
    end
  end

  def previous_ref_as_git_ref(potential_git_ref) do
    if git_present?() do
      if git_ref_exists?(potential_git_ref) do
        {:git, potential_git_ref}
      end
    else
      {:error, "could not run `git`"}
    end
  end

  def previous_ref_as_git_merge_base(potential_git_ref) do
    if git_present?() do
      if git_ref_exists?(potential_git_ref) do
        {:git_merge_base, potential_git_ref}
      end
    else
      {:error, "could not run `git`"}
    end
  end

  def previous_ref_as_path(potential_path) do
    if File.exists?(potential_path) do
      {:path, potential_path}
    else
      {:error, "could not find given path: #{potential_path}"}
    end
  end

  defp git_present? do
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
end
