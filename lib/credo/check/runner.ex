defmodule Credo.Check.Runner do
  alias Credo.Config
  alias Credo.SourceFile
  alias Credo.Service.SourceFileIssues

  def run(source_files, config) when is_list(source_files) do
    config =
      config
      |> set_lint_attributes(source_files)
      |> exclude_low_priority_checks(config.min_priority - 9)

    {_time_run_on_all, source_files_after_run_on_all} =
      :timer.tc fn ->
        source_files
        |> run_checks_that_run_on_all(config)
      end

    #IO.inspect time_run_on_all

    {_time_run, source_files} =
      :timer.tc fn ->
        source_files_after_run_on_all
        |> Enum.map(&Task.async(fn -> run(&1, config) end))
        |> Enum.map(&Task.await(&1, :infinity))
      end

    #IO.inspect time_run

    {source_files, config}
  end

  def run(%SourceFile{} = source_file, config) do
    checks = config |> Config.checks |> Enum.reject(&run_on_all_check?/1)

    issues = run_checks(source_file, checks, config)
    %SourceFile{source_file | issues: source_file.issues ++ issues}
  end

  defp set_lint_attributes(config, source_files) do
    lint_attribute_map =
      source_files
      |> run_linter_attribute_reader(config)
      |> Enum.reduce(%{}, fn(source_file, memo) ->
          # TODO: we should modify the config "directly" instead of going
          # through the SourceFile
          Map.put(memo, source_file.filename, source_file.lint_attributes)
        end)

    %Config{config | lint_attribute_map: lint_attribute_map}
  end

  defp run_linter_attribute_reader(source_files, config) do
    checks = [{Credo.Check.FindLintAttributes}]

    Enum.reduce(checks, source_files, fn(check_tuple, source_files) ->
      run_check(check_tuple, source_files, config)
    end)
  end

  defp exclude_low_priority_checks(config, below_priority) do
    checks =
      config.checks
      |> Enum.reject(fn
          ({check}) -> check.base_priority < below_priority
          ({check, _}) -> check.base_priority < below_priority
        end)

    %Config{config | checks: checks}
  end

  defp run_checks_that_run_on_all(source_files, config) do
    checks = config |> Config.checks |> Enum.filter(&run_on_all_check?/1)

    checks
    |> Enum.map(&Task.async(fn ->
        run_check(&1, source_files, config)
      end))
    |> Enum.each(&Task.await(&1, :infinity))

    source_files
    |> SourceFileIssues.update_in_source_files
  end

  defp run_checks(%SourceFile{} = source_file, checks, config) when is_list(checks) do
    checks
    |> Enum.flat_map(&run_check(&1, source_file, config))
  end

  defp run_check({_check, false}, source_files, _config) when is_list(source_files) do
    source_files
  end
  defp run_check({_check, false}, _source_file, _config) do
    []
  end
  defp run_check({check}, source_file, config) do
    run_check({check, []}, source_file, config)
  end
  defp run_check({check, params}, source_file, config) do
    try do
      check.run(source_file, params)
    rescue
      error ->
        IO.puts(:stderr, "Error while running #{check} on #{source_file.filename}")
        if config.crash_on_error do
          reraise error, System.stacktrace()
        else
          []
        end
    end
  end

  defp run_on_all_check?({check}), do: check.run_on_all?
  defp run_on_all_check?({check, _params}), do: check.run_on_all?
end
