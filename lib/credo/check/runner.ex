defmodule Credo.Check.Runner do
  alias Credo.CLI.Output.UI
  alias Credo.Config
  alias Credo.SourceFile
  alias Credo.Service.SourceFileIssues

  @doc false
  def run(source_files, config) when is_list(source_files) do
    {_time_run_on_all, _source_files_after_run_on_all} =
      :timer.tc fn ->
        run_checks_that_run_on_all(source_files, config)
      end

    {_time_run, _source_files} =
      :timer.tc fn ->
        source_files
        |> Enum.map(&Task.async(fn -> run(&1, config) end))
        |> Enum.map(&Task.await(&1, :infinity))
      end

    :ok
  end
  def run(%SourceFile{} = source_file, config) do
    checks =
      config
      |> Config.checks
      |> Enum.reject(&run_on_all_check?/1)

    case run_checks(source_file, checks, config) do
      [] ->
        nil
      issues ->
        SourceFileIssues.append(config, source_file, issues)
    end

    :ok
  end

  @doc """
  Prepares the Config struct based on a given list of `source_files`.
  """
  def prepare_config(config) do
    source_files = Config.get_source_files(config)

    config
    |> set_lint_attributes(source_files)
    |> set_config_comments(source_files)
    |> exclude_low_priority_checks(config.min_priority - 9)
    |> exclude_checks_based_on_elixir_version
  end

  defp set_lint_attributes(config, source_files) do
    lint_attribute_map = run_linter_attribute_reader(source_files, config)

    if Enum.any?(lint_attribute_map, fn({_, value}) -> value != [] end) do
      Credo.CLI.Output.UI.warn ""
      Credo.CLI.Output.UI.warn [:bright, :orange,
        "@lint attributes are deprecated since Credo v0.8 because they trigger\n",
        "compiler warnings on Elixir v1.4.\n\n",
      ]
      Credo.CLI.Output.UI.warn ""
    end

    %Config{config | lint_attribute_map: lint_attribute_map}
  end

  defp run_linter_attribute_reader(source_files, config) do
    {Credo.Check.FindLintAttributes}
    |> run_check(source_files, config)
    |> Enum.into(%{})
  end

  defp set_config_comments(config, source_files) do
    config_comment_map = run_config_comment_finder(source_files, config)

    %Config{config | config_comment_map: config_comment_map}
  end

  defp run_config_comment_finder(source_files, config) do
    {Credo.Check.ConfigCommentFinder}
    |> run_check(source_files, config)
    |> Enum.into(%{})
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

    :ok
  end

  defp run_checks(%SourceFile{} = source_file, checks, config) when is_list(checks) do
    Enum.flat_map(checks, &run_check(&1, source_file, config))
  end

  # Returns issues
  defp run_check({_check, false}, source_files, _config) when is_list(source_files) do
    source_files
  end
  defp run_check({_check, false}, _source_file, _config) do
    []
  end
  defp run_check({check}, source_file, config) do
    run_check({check, []}, source_file, config)
  end
  defp run_check({check, params}, source_files, config) when is_list(source_files) do
    try do
      check.run(source_files, config, params)
    rescue
      error ->
        warn_about_failed_run(check, source_files)

        if config.crash_on_error do
          reraise error, System.stacktrace()
        else
          []
        end
    end
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
