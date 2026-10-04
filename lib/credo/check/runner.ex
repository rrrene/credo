defmodule Credo.Check.Runner do
  @moduledoc false

  # This module is responsible for running checks based on the context represented
  # by the current `Credo.Execution`.

  alias Credo.Check.Params
  alias Credo.CLI.Output.UI
  alias Credo.Execution

  require Credo.Execution.Timing, as: Timing

  @doc """
  Runs all checks on all source files (according to the config).
  """
  def run(%Execution{} = exec) do
    {all_check_tuples, _, _} = Execution.checks(exec)

    check_tuples_by_starting_phase =
      all_check_tuples
      |> Enum.group_by(fn {check, _params} -> check.starting_phase() end)
      |> Enum.sort_by(fn {key, _check_tuples} -> key end)

    Enum.each(check_tuples_by_starting_phase, &run_checks_in_starting_phase(exec, &1))

    :ok
  end

  defp run_checks_in_starting_phase(%Execution{} = exec, {_starting_phase, check_tuples}) do
    buckets = Enum.group_by(check_tuples, fn {check, _params} -> check.managed_traversal() end)

    checks_wo_managed_traversal = Map.get(buckets, false, [])

    [
      Task.async_stream(checks_wo_managed_traversal, &run_check(exec, &1), timeout: :infinity, ordered: false),
      __MODULE__.ManagedTraversal.AST.to_stream(exec, Map.get(buckets, :ast)),
      __MODULE__.ManagedTraversal.Tokens.to_stream(exec, Map.get(buckets, :tokens))
    ]
    |> Enum.reject(&is_nil/1)
    |> Stream.concat()
    |> Stream.run()
  end

  defp run_check(%Execution{} = exec, {check, params}) do
    Timing.span exec, "check", task: exec.private.current_task, check: check do
      do_run_check(exec, {check, params})
    end
  end

  defp do_run_check(exec, {check, params}) do
    rerun_files_that_changed = Params.get_rerun_files_that_changed(params)

    known_files = exec |> Execution.get_source_files() |> Enum.map(& &1.filename)
    files_included = Params.files_included(params, check, known_files)
    files_excluded = Params.files_excluded(params, check)

    found_relevant_files =
      cond do
        files_included == known_files and files_excluded == [] ->
          []

        exec.config.read_from_stdin ->
          # TODO: I am unhappy with how convoluted this gets
          #       but it is necessary to avoid hitting the filesystem when reading from STDIN
          [%Credo.SourceFile{filename: filename}] = Execution.get_source_files(exec)

          file_included? =
            if files_included != known_files do
              Credo.Sources.filename_matches?(filename, files_included)
            else
              true
            end

          file_excluded? =
            if files_excluded != [] do
              Credo.Sources.filename_matches?(filename, files_excluded)
            else
              false
            end

          if !file_included? || file_excluded? do
            :skip_run
          else
            []
          end

        true ->
          exec
          |> Execution.working_dir()
          |> Credo.Sources.find_in_dir(files_included, files_excluded)
          |> case do
            [] -> :skip_run
            files -> files
          end
      end

    source_files =
      exec
      |> Execution.get_source_files()
      |> filter_source_files(rerun_files_that_changed)
      |> filter_source_files(found_relevant_files)

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

  defp filter_source_files(_source_files, :skip_run) do
    []
  end

  defp filter_source_files(source_files, []) do
    source_files
  end

  defp filter_source_files(source_files, files_included) do
    Enum.filter(source_files, fn source_file ->
      Enum.member?(files_included, Path.expand(source_file.filename))
    end)
  end

  defp warn_about_failed_run(check, %Credo.SourceFile{} = source_file) do
    UI.warn("Error while running #{check} on #{source_file.filename}")
  end

  defp warn_about_failed_run(check, _) do
    UI.warn("Error while running #{check}")
  end
end
