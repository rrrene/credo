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
  def run(%Execution{} = exec) do
    {all_check_tuples, _, _} = Execution.checks(exec)

    check_tuples_grouped_by_group =
      all_check_tuples
      |> Enum.group_by(fn {check, _params} -> check.scheduled_in_group() end)
      |> Enum.sort_by(fn {key, _check_tuples} -> key end)
      |> Enum.map(fn {_key, check_tuples} -> check_tuples end)

    Enum.each(check_tuples_grouped_by_group, fn check_tuples ->
      buckets = Enum.group_by(check_tuples, fn {check, _params} -> check.managed_traversal() end)

      checks_wo_managed_traversal = Map.get(buckets, false, [])

      [
        Task.async_stream(checks_wo_managed_traversal, &run_check(exec, &1), timeout: :infinity, ordered: false),
        __MODULE__.ManagedTraversalAST.to_stream(exec, Map.get(buckets, :ast))
      ]
      |> Enum.reject(&is_nil/1)
      |> Stream.concat()
      |> Stream.run()
    end)

    :ok
  end

  defmodule ManagedTraversalAST do
    def to_stream(exec, checks)

    def to_stream(_, nil), do: nil
    def to_stream(_, []), do: nil

    def to_stream(%Credo.Execution{} = exec, [_ | _] = check_tuples) do
      source_files = Execution.get_source_files(exec)
      filenames = Enum.map(source_files, & &1.filename)

      Task.async_stream(source_files, &run_source_file(exec, check_tuples, filenames, &1),
        timeout: :infinity,
        ordered: false
      )
    end

    defp run_source_file(exec, check_tuples, filenames, source_file) do
      walker_ctx = build_all_check_contexts(check_tuples, source_file)

      issues =
        source_file
        |> Credo.Code.prewalk(&walk(&1, &2, filenames), walker_ctx)
        |> Enum.flat_map(fn {check, %{__ctx: _} = check_ctx} -> check.issues_from_context(check_ctx) end)

      Credo.Execution.ExecutionIssues.append(exec, issues)
    end

    defp build_all_check_contexts(walker_checks, source_file) do
      walker_checks
      |> Enum.map(fn {check, params} ->
        {check, check.build_context(source_file, params)}
      end)
      |> Map.new()
    end

    defp walk(ast, walker_ctx, known_files) do
      walker_ctx =
        Enum.reduce(walker_ctx, walker_ctx, fn
          {check, %{source_file: %{filename: filename}, params: params} = check_ctx}, inner_walker_ctx ->
            if run_check_for_file?(filename, known_files, check, params) do
              try do
                check_ctx =
                  case check.handle_walk(ast, check_ctx) do
                    %{__ctx: _} = check_ctx -> check_ctx
                    {_ast, %{__ctx: _} = check_ctx} -> check_ctx
                  end

                Map.put(inner_walker_ctx, check, check_ctx)
              rescue
                error ->
                  UI.warn([
                    :orange,
                    "Error while running #{check} on #{inner_walker_ctx.__meta.filename}:#{inner_walker_ctx.__meta.line_no}"
                  ])

                  reraise error, __STACKTRACE__
              end
            else
              inner_walker_ctx
            end
        end)

      {ast, walker_ctx}
    end

    defp run_check_for_file?(filename, known_files, check, params) do
      files_included = Params.files_included(params, check, known_files)
      files_excluded = Params.files_excluded(params, check)

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

      file_included? && !file_excluded?
    end
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
