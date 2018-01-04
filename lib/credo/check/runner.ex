defmodule Credo.Check.Runner do
  alias Credo.CLI.Output.UI
  alias Credo.Execution
  alias Credo.SourceFile
  alias Credo.Execution.Issues

  @doc false
  def run(source_files, exec) when is_list(source_files) do
    {_time_run_on_all, _source_files_after_run_on_all} =
      :timer.tc(fn ->
        run_checks_that_run_on_all(source_files, exec)
      end)

    {_time_run, _source_files} =
      :timer.tc(fn ->
        source_files
        |> Enum.map(&Task.async(fn -> run(&1, exec) end))
        |> Enum.map(&Task.await(&1, :infinity))
      end)

    :ok
  end

  def run(%SourceFile{} = source_file, exec) do
    checks =
      exec
      |> Execution.checks()
      |> Enum.reject(&run_on_all_check?/1)

    case run_checks(source_file, checks, exec) do
      [] ->
        nil

      issues ->
        Issues.append(exec, source_file, issues)
    end

    :ok
  end

  @doc "TODO: deprecated"
  def run_linter_attribute_reader(source_files, exec) do
    {Credo.Check.FindLintAttributes}
    |> run_check(source_files, exec)
    |> Enum.into(%{})
  end

  @doc "Runs the ConfigCommentFinder"
  def run_config_comment_finder(source_files, exec) do
    {Credo.Check.ConfigCommentFinder}
    |> run_check(source_files, exec)
    |> Enum.into(%{})
  end

  defp run_checks_that_run_on_all(source_files, exec) do
    checks =
      exec
      |> Execution.checks()
      |> Enum.filter(&run_on_all_check?/1)

    checks
    |> Enum.map(
      &Task.async(fn ->
        run_check(&1, source_files, exec)
      end)
    )
    |> Enum.each(&Task.await(&1, :infinity))

    :ok
  end

  defp run_checks(%SourceFile{} = source_file, checks, exec)
       when is_list(checks) do
    Enum.flat_map(checks, &run_check(&1, source_file, exec))
  end

  # Returns issues
  defp run_check({_check, false}, source_files, _exec)
       when is_list(source_files) do
    source_files
  end

  defp run_check({_check, false}, _source_file, _exec) do
    []
  end

  defp run_check({check}, source_file, exec) do
    run_check({check, []}, source_file, exec)
  end

  defp run_check({check, params}, source_files, exec) when is_list(source_files) do
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

  defp run_check({check, params}, source_file, exec) do
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
    UI.warn("Error while running #{check} on #{source_file.filename}")
  end

  defp warn_about_failed_run(check, _) do
    UI.warn("Error while running #{check}")
  end

  defp run_on_all_check?({check}), do: check.run_on_all?
  defp run_on_all_check?({check, _params}), do: check.run_on_all?
end
