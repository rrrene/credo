defmodule Credo.Check.Runner do
  @moduledoc false

  # This module is responsible for running checks based on the context represented
  # by the current `Credo.Execution`.

  alias Credo.Check.Params
  alias Credo.CLI.Output.UI
  alias Credo.Execution
  alias Credo.Execution.ExecutionTiming

  @doc """
  Runs all checks on all source files (according to the config).
  """
  def run(source_files, %Execution{} = exec) when is_list(source_files) do
    {all_check_tuples, _, _} = Execution.checks(exec)

    check_tuples_grouped_by_group =
      all_check_tuples
      |> Enum.group_by(fn {check, _params} -> check.scheduled_in_group() end)
      |> Enum.sort_by(fn {key, _check_tuples} -> key end)
      |> Enum.map(fn {_key, check_tuples} -> check_tuples end)

    Enum.each(check_tuples_grouped_by_group, fn check_tuples ->
      check_tuples
      |> Task.async_stream(&run_check(exec, &1),
        timeout: :infinity,
        ordered: false
      )
      |> Stream.run()
    end)

    :ok
  end

  defp run_check(%Execution{config: %{debug: true}} = exec, {check, params}) do
    ExecutionTiming.run(&do_run_check/2, [exec, {check, params}])
    |> ExecutionTiming.append(exec, task: exec.private.current_task, check: check)
  end

  defp run_check(exec, {check, params}) do
    do_run_check(exec, {check, params})
  end

  defp do_run_check(exec, {check, params}) do
    rerun_files_that_changed = Params.get_rerun_files_that_changed(params)

    files_included = Params.files_included(params, check)
    files_excluded = Params.files_excluded(params, check)

    source_files =
      exec
      |> Execution.get_source_files()
      |> filter_source_files(rerun_files_that_changed)
      |> filter_source_files_for_check(files_included, files_excluded)

    try do
      check.run_on_all_source_files(exec, source_files, params)
    rescue
      error ->
        warn_about_failed_run(check, source_files)

        if exec.config.crash_on_error do
          reraise error, __STACKTRACE__
        else
          []
        end
    end
  end

  defp filter_source_files(source_files, []) do
    source_files
  end

  defp filter_source_files(source_files, files_that_changed) do
    Enum.filter(source_files, fn source_file ->
      Enum.member?(files_that_changed, Path.expand(source_file.filename))
    end)
  end

  defp filter_source_files_for_check(source_files, nil, []) do
    source_files
  end

  defp filter_source_files_for_check(source_files, files_included, files_excluded) do
    Enum.filter(source_files, fn %{filename: filename} ->
      included? = is_nil(files_included) or Credo.Sources.filename_matches?(filename, files_included)
      excluded? = files_excluded != [] and Credo.Sources.filename_matches?(filename, files_excluded)
      included? and not excluded?
    end)
  end

  defp warn_about_failed_run(check, %Credo.SourceFile{} = source_file) do
    UI.warn("Error while running #{check} on #{source_file.filename}")
  end

  defp warn_about_failed_run(check, _) do
    UI.warn("Error while running #{check}")
  end
end
