defmodule Credo.Check.Runner do
  alias Credo.CLI.Output.UI
  alias Credo.Config
  alias Credo.SourceFile
  alias Credo.Service.SourceFileIssues

  @doc false
  def run(source_files, config) when is_list(source_files) do
    {_time_run_on_all, source_files_after_run_on_all} =
      :timer.tc fn ->
        run_checks_that_run_on_all(source_files, config)
      end

    {_time_run, source_files} =
      :timer.tc fn ->
        source_files_after_run_on_all
        |> Enum.map(&Task.async(fn -> run(&1, config) end))
        |> Enum.map(&Task.await(&1, :infinity))
      end

    {source_files, config}
  end
  def run(%SourceFile{} = source_file, config) do
    checks =
      config
      |> Config.checks
      |> Enum.reject(&run_on_all_check?/1)

    issues = run_checks(source_file, checks, config)

    %SourceFile{source_file | issues: source_file.issues ++ issues}
  end

  @doc """
  Prepares the Config struct based on a given list of `source_files`.
  """
  def prepare_config(config) do
    prepare_config(config, config.source_files)
  end
  def prepare_config(config, source_files) do
    # TODO: remove prepare_config/2
    config
    |> set_lint_attributes(source_files)
    |> exclude_low_priority_checks(config.min_priority - 9)
    |> exclude_checks_based_on_elixir_version
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

    if lint_attribute_map |> Enum.filter(fn({_, value}) -> value != [] end) != [] do
      Credo.CLI.Output.UI.warn ""
      Credo.CLI.Output.UI.warn [:orange,
        "@lint attributes will be deprecated in the Credo v0.8 because they trigger\n",
        "compiler warnings on Elixir v1.4.\n\n",
        "Please consider reporting the cases where you needed @lint attributes\n",
        "to help us devise a new solution: https://github.com/rrrene/credo/issues/new"]
      Credo.CLI.Output.UI.warn ""
    end

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
      Enum.reject(config.checks, fn
        ({check}) -> check.base_priority < below_priority
        ({_check, false}) -> true
        ({check, opts}) ->
          (opts[:priority] || check.base_priority) < below_priority
      end)

    %Config{config | checks: checks}
  end

  defp exclude_checks_based_on_elixir_version(config) do
    version = System.version()
    skipped_checks = Enum.reject(config.checks, &matches_requirement?(&1, version))
    checks = Enum.filter(config.checks, &matches_requirement?(&1, version))

    %Config{config | checks: checks, skipped_checks: skipped_checks}
  end

  defp matches_requirement?({check, _}, version) do
    matches_requirement?({check}, version)
  end
  defp matches_requirement?({check}, version) do
    Version.match?(version, check.elixir_version)
  end

  defp run_checks_that_run_on_all(source_files, config) do
    checks =
      config
      |> Config.checks
      |> Enum.filter(&run_on_all_check?/1)

    checks
    |> Enum.map(&Task.async(fn ->
        run_check(&1, source_files, config)
      end))
    |> Enum.each(&Task.await(&1, :infinity))

    SourceFileIssues.update_in_source_files(source_files)
  end

  defp run_checks(%SourceFile{} = source_file, checks, config) when is_list(checks) do
    Enum.flat_map(checks, &run_check(&1, source_file, config))
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
        warn_about_failed_run(check, source_file)
        if config.crash_on_error do
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
