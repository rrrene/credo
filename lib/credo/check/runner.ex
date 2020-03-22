defmodule Credo.Check.Runner do
  @moduledoc false

  # This module is responsible for running checks based on the context represented
  # by the current `Credo.Execution`.

  alias Credo.CLI.Output.UI
  alias Credo.Execution
  alias Credo.Execution.ExecutionIssues
  alias Credo.Execution.ExecutionTiming
  alias Credo.SourceFile

  @doc """
  Runs all checks on all source files (according to the config).
  """
  def run(source_files, exec) when is_list(source_files) do
    checks =
      exec
      |> Execution.checks()
      |> warn_about_ineffective_patterns(exec)

    {run_on_all_checks, other_checks} = Enum.split_with(checks, &run_on_all_check?/1)

    run_on_all_checks
    |> Enum.map(&Task.async(fn -> run_check_on_source_files(&1, source_files, exec) end))
    |> Enum.each(&Task.await(&1, :infinity))

    source_files
    |> Enum.map(&Task.async(fn -> run_checks_and_append_issues(&1, exec, other_checks) end))
    |> Enum.each(&Task.await(&1, :infinity))

    :ok
  end

  defp run_on_all_check?({check}), do: check.run_on_all?
  defp run_on_all_check?({check, _params}), do: check.run_on_all?

  defp run_checks_and_append_issues(%SourceFile{} = source_file, exec, checks) do
    case run_checks_individually(source_file, checks, exec) do
      [] ->
        nil

      list ->
        Enum.each(list, &append_issues_and_timings(exec, source_file, &1))
    end

    :ok
  end

  defp append_issues_and_timings(exec, source_file, {issues, nil}) do
    ExecutionIssues.append(exec, source_file, issues)
  end

  defp append_issues_and_timings(exec, source_file, {issues, {check, filename, started_at, time}}) do
    ExecutionIssues.append(exec, source_file, issues)

    ExecutionTiming.append(
      exec,
      [task: exec.current_task, check: check, source_file: filename],
      started_at,
      time
    )
  end

  defp append_issues_and_timings(exec, source_file, {issues, {check, started_at, time}}) do
    ExecutionIssues.append(exec, source_file, issues)

    ExecutionTiming.append(exec, [task: exec.current_task, check: check], started_at, time)
  end

  @doc false
  def run_config_comment_finder(source_files, exec) do
    case run_check_on_source_files({Credo.Check.ConfigCommentFinder}, source_files, exec) do
      {issues, nil} ->
        Enum.into(issues, %{})

      {issues, {check, started_at, time}} ->
        ExecutionTiming.append(
          exec,
          [task: exec.current_task, check: check, alias: "ConfigCommentFinder"],
          started_at,
          time
        )

        Enum.into(issues, %{})
    end
  end

  #
  # Run a single check on a list of source files
  #

  defp run_check_on_source_files({_check, false}, _source_files, _exec), do: []

  defp run_check_on_source_files({check}, source_files, exec) do
    run_check_on_source_files({check, []}, source_files, exec)
  end

  defp run_check_on_source_files(
         {check, params},
         source_files,
         %Credo.Execution{debug: true} = exec
       ) do
    {started_at, time, issues} =
      ExecutionTiming.run(fn ->
        do_run_check_on_source_files({check, params}, source_files, exec)
      end)

    {issues, {check, started_at, time}}
  end

  defp run_check_on_source_files({check, params}, source_files, exec) do
    issues = do_run_check_on_source_files({check, params}, source_files, exec)

    {issues, nil}
  end

  defp do_run_check_on_source_files({check, params}, source_files, exec) do
    try do
      check.run(source_files, exec, params)
    rescue
      error ->
        warn_about_failed_run(check, source_files)

        if exec.crash_on_error do
          reraise error, System.stacktrace()
        else
          []
        end
    end
  end

  #
  # Run a single check on a single source file
  #

  defp run_checks_individually(%SourceFile{} = source_file, checks, exec) do
    Enum.map(checks, &run_check_on_single_source_file(&1, source_file, exec))
  end

  defp run_check_on_single_source_file({check}, source_file, exec) do
    run_check_on_single_source_file({check, []}, source_file, exec)
  end

  defp run_check_on_single_source_file({_check, false}, _source_file, _exec), do: []

  defp run_check_on_single_source_file(
         {check, params},
         source_file,
         %Credo.Execution{debug: true} = exec
       ) do
    {started_at, time, issues} =
      ExecutionTiming.run(fn ->
        do_run_check_on_single_source_file({check, params}, source_file, exec)
      end)

    {issues, {check, source_file.filename, started_at, time}}
  end

  defp run_check_on_single_source_file({check, params}, source_file, exec) do
    issues = do_run_check_on_single_source_file({check, params}, source_file, exec)

    {issues, nil}
  end

  defp do_run_check_on_single_source_file({check, params}, source_file, exec) do
    try do
      check.run(source_file, params)
    rescue
      error ->
        warn_about_failed_run(check, source_file)

        if exec.crash_on_error do
          reraise error, System.stacktrace()
        else
          []
        end
    end
  end

  defp warn_about_failed_run(check, %SourceFile{} = source_file) do
    UI.warn([:red, "** (config) Error while running #{check} on #{source_file.filename}"])
  end

  defp warn_about_failed_run(check, _) do
    UI.warn([:red, "** (config) Error while running #{check}"])
  end

  defp warn_about_ineffective_patterns(
         {checks, [], _ignored_checks},
         %Execution{only_checks: [_ | _] = only_checks}
       ) do
    UI.warn([
      :red,
      "** (config) A pattern was given to filter checks, but it did not match any: ",
      inspect(only_checks)
    ])

    checks
  end

  defp warn_about_ineffective_patterns(
         {checks, _included_checks, []},
         %Execution{ignore_checks: [_ | _] = ignore_checks}
       ) do
    UI.warn([
      :red,
      "** (config) A pattern was given to ignore checks, but it did not match any: ",
      inspect(ignore_checks)
    ])

    checks
  end

  defp warn_about_ineffective_patterns({checks, _, _}, _) do
    checks
  end
end
