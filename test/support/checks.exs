defmodule Credo.Test.Checks do
  use ExUnit.Case

  alias Credo.Execution.ExecutionIssues
  alias Credo.SourceFile

  def assert_trigger(issue, trigger)

  def assert_trigger([issue], trigger), do: [assert_trigger(issue, trigger)]

  def assert_trigger(issue, trigger) do
    assert trigger == issue.trigger

    issue
  end

  def refute_issues(source_file, check \\ nil, params \\ []) do
    issues = issues_for(source_file, check, create_config(), params)

    assert [] == issues,
           "There should be no issues, got #{Enum.count(issues)}: #{to_inspected(issues)}"

    issues
  end

  def assert_issue(source_file, callback) when is_function(callback) do
    assert_issue(source_file, nil, [], callback)
  end

  def assert_issue(source_file, check, callback) when is_function(callback) do
    assert_issue(source_file, check, [], callback)
  end

  def assert_issue(source_file, check \\ nil, params \\ [], callback \\ nil) do
    issues = issues_for(source_file, check, create_config(), params)

    refute Enum.empty?(issues), "There should be one issue, got none."

    assert Enum.count(issues) == 1,
           "There should be only 1 issue, got #{Enum.count(issues)}: #{to_inspected(issues)}"

    if callback do
      issues |> List.first() |> callback.()
    end

    issues
  end

  def assert_issues(source_file, callback) when is_function(callback) do
    assert_issues(source_file, nil, [], callback)
  end

  def assert_issues(source_file, check, callback) when is_function(callback) do
    assert_issues(source_file, check, [], callback)
  end

  def assert_issues(source_file, check \\ nil, params \\ [], callback \\ nil) do
    issues = issues_for(source_file, check, create_config(), params)

    assert Enum.count(issues) > 0, "There should be multiple issues, got none."

    assert Enum.count(issues) > 1,
           "There should be more than one issue, got: #{to_inspected(issues)}"

    if callback, do: callback.(issues)

    issues
  end

  defp issues_for(source_files, nil, exec, _) when is_list(source_files) do
    source_files
    |> Enum.flat_map(&get_issues_from_source_file(&1, exec))
    |> Enum.map(fn
      %Credo.Issue{} = issue ->
        issue

      value ->
        raise "Expected %Issue{}, got: #{inspect(value)}"
    end)
  end

  defp issues_for(source_files, check, _exec, params)
       when is_list(source_files) do
    exec = create_config()

    if check.run_on_all? do
      :ok = check.run(source_files, exec, params)

      source_files
      |> Enum.flat_map(&(&1 |> get_issues_from_source_file(exec)))
    else
      source_files
      |> check.run(params)
      |> Enum.flat_map(&(&1 |> get_issues_from_source_file(exec)))
    end
  end

  defp issues_for(%SourceFile{} = source_file, nil, exec, _) do
    source_file |> get_issues_from_source_file(exec)
  end

  defp issues_for(%SourceFile{} = source_file, check, _exec, params) do
    _issues = check.run(source_file, params)
  end

  def to_inspected(value) do
    value
    |> Inspect.Algebra.to_doc(%Inspect.Opts{})
    |> Inspect.Algebra.format(50)
    |> Enum.join("")
  end

  defp create_config do
    %Credo.Execution{}
    |> Credo.Execution.ExecutionSourceFiles.start_server()
    |> Credo.Execution.ExecutionIssues.start_server()
    |> Credo.Execution.ExecutionTiming.start_server()
  end

  defp get_issues_from_source_file(source_file, exec) do
    ExecutionIssues.get(exec, source_file)
  end
end
