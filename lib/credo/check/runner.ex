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
  def run(source_files, exec) when is_list(source_files) do
    check_tuples =
      exec
      |> Execution.checks()
      |> warn_about_ineffective_patterns(exec)
      |> fix_deprecated_notation_for_checks_without_params()

    max_concurrency = if exec.profile, do: 1, else: System.schedulers_online()

    check_tuples
    |> Task.async_stream(&run_check(exec, &1),
      timeout: :infinity,
      ordered: not exec.profile,
      max_concurrency: max_concurrency
    )
    |> Stream.run()

    :ok
  end

  defp run_check(%Execution{} = exec, {check, params}) when exec.profile or exec.debug do
    ExecutionTiming.run(&do_run_check/2, [exec, {check, params}])
    |> tap(fn
      {_, usec, _} when usec > 10_000 and exec.profile ->
        IO.puts("#{check} took #{usec / 1000}ms")

      _ ->
        :ok
    end)
    |> ExecutionTiming.append(exec, task: exec.current_task, check: check)
  end

  defp run_check(exec, {check, params}) do
    do_run_check(exec, {check, params})
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

        exec.read_from_stdin ->
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

        if exec.crash_on_error do
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

  defp fix_deprecated_notation_for_checks_without_params(checks) do
    Enum.map(checks, fn
      {check} -> {check, []}
      {check, params} -> {check, params}
    end)
  end

  defp warn_about_ineffective_patterns(
         {checks, _included_checks, []},
         %Execution{ignore_checks: [_ | _] = ignore_checks}
       ) do
    UI.warn([
      :red,
      "A pattern was given to ignore checks, but it did not match any: ",
      inspect(ignore_checks)
    ])

    checks
  end

  defp warn_about_ineffective_patterns({checks, _, _}, _) do
    checks
  end
end
