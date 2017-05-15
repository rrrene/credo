defmodule Credo.Check.Runner do
  alias Credo.CLI.Output.UI
  alias Credo.Execution
  alias Credo.SourceFile
  alias Credo.Execution.Issues

  @doc false
  def run(source_files, exec) when is_list(source_files) do
    {_time_run_on_all, _source_files_after_run_on_all} =
      :timer.tc fn ->
        run_checks_that_run_on_all(source_files, exec)
      end

    {_time_run, _source_files} =
      :timer.tc fn ->
        source_files
        |> Enum.map(&Task.async(fn -> run(&1, exec) end))
        |> Enum.map(&Task.await(&1, :infinity))
      end

    :ok
  end
  def run(%SourceFile{} = source_file, exec) do
    checks =
      exec
      |> Execution.checks
      |> Enum.reject(&run_on_all_check?/1)

    case run_checks(source_file, checks, exec) do
      [] ->
        nil
      issues ->
        Issues.append(exec, source_file, issues)
    end

    :ok
  end

  @doc """
  Prepares the Execution struct based on a given list of `source_files`.
  """
  def prepare_config(exec) do
    source_files = Execution.get_source_files(exec)

    exec
    |> set_lint_attributes(source_files)
    |> set_config_comments(source_files)
    |> exclude_low_priority_checks(exec.min_priority - 9)
    |> exclude_checks_based_on_elixir_version
  end

  defp set_lint_attributes(exec, source_files) do
    lint_attribute_map = run_linter_attribute_reader(source_files, exec)

    if Enum.any?(lint_attribute_map, fn({_, value}) -> value != [] end) do
      Credo.CLI.Output.UI.warn ""
      Credo.CLI.Output.UI.warn [:bright, :orange,
        "@lint attributes are deprecated since Credo v0.8 because they trigger\n",
        "compiler warnings on Elixir v1.4.\n",
      ]
      Credo.CLI.Output.UI.warn [:orange,
        "You can use comments to disable individual lines of code.\n",
        "To see how this works, please refer to Credo's README:\n",
        "https://github.com/rrrene/credo"
      ]
      Credo.CLI.Output.UI.warn ""
    end

    %Execution{exec | lint_attribute_map: lint_attribute_map}
  end

  defp run_linter_attribute_reader(source_files, exec) do
    {Credo.Check.FindLintAttributes}
    |> run_check(source_files, exec)
    |> Enum.into(%{})
  end

  defp set_config_comments(exec, source_files) do
    config_comment_map = run_config_comment_finder(source_files, exec)

    %Execution{exec | config_comment_map: config_comment_map}
  end

  defp run_config_comment_finder(source_files, exec) do
    {Credo.Check.ConfigCommentFinder}
    |> run_check(source_files, exec)
    |> Enum.into(%{})
  end

  defp exclude_low_priority_checks(exec, below_priority) do
    checks =
      Enum.reject(exec.checks, fn
        ({check}) -> check.base_priority < below_priority
        ({_check, false}) -> true
        ({check, opts}) ->
          (opts[:priority] || check.base_priority) < below_priority
      end)

    %Execution{exec | checks: checks}
  end

  defp exclude_checks_based_on_elixir_version(exec) do
    version = System.version()
    skipped_checks = Enum.reject(exec.checks, &matches_requirement?(&1, version))
    checks = Enum.filter(exec.checks, &matches_requirement?(&1, version))

    %Execution{exec | checks: checks, skipped_checks: skipped_checks}
  end

  defp matches_requirement?({check, _}, version) do
    matches_requirement?({check}, version)
  end
  defp matches_requirement?({check}, version) do
    Version.match?(version, check.elixir_version)
  end

  defp run_checks_that_run_on_all(source_files, exec) do
    checks =
      exec
      |> Execution.checks
      |> Enum.filter(&run_on_all_check?/1)

    checks
    |> Enum.map(&Task.async(fn ->
        run_check(&1, source_files, exec)
      end))
    |> Enum.each(&Task.await(&1, :infinity))

    :ok
  end

  defp run_checks(%SourceFile{} = source_file, checks, exec) when is_list(checks) do
    Enum.flat_map(checks, &run_check(&1, source_file, exec))
  end

  # Returns issues
  defp run_check({_check, false}, source_files, _exec) when is_list(source_files) do
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
