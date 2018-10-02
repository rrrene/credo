Code.require_file("support/test_application.exs", __DIR__)

Credo.Test.Application.start([], [])

ExUnit.start()

check_version =
  ~w(1.6.5 1.7.0)
  |> Enum.reduce([], fn version, acc ->
    # allow -dev versions so we can test before the Elixir release.
    if System.version() |> Version.match?("< #{version}-dev") do
      acc ++ [needs_elixir: version]
    else
      acc
    end
  end)

exclude = Keyword.merge([to_be_implemented: true], check_version)

ExUnit.configure(exclude: exclude)

defmodule Credo.TestHelper do
  defmacro __using__(_) do
    quote do
      use ExUnit.Case
      import CredoSourceFileCase
      import CredoCheckCase
    end
  end
end

defmodule CredoSourceFileCase do
  alias Credo.Test.FilenameGenerator

  def to_source_file(source) do
    to_source_file(source, FilenameGenerator.next())
  end

  def to_source_file(source, filename) do
    case Credo.SourceFile.parse(source, filename) do
      %{status: :valid} = source_file ->
        source_file

      _ ->
        raise "Source could not be parsed!"
    end
  end

  def to_source_files(list) do
    Enum.map(list, &to_source_file/1)
  end
end

defmodule CredoCheckCase do
  use ExUnit.Case

  alias Credo.Execution.Issues
  alias Credo.SourceFile

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

  def assert_trigger([issue], trigger), do: [assert_trigger(issue, trigger)]

  def assert_trigger(issue, trigger) do
    assert trigger == issue.trigger

    issue
  end

  def to_inspected(value) do
    value
    |> Inspect.Algebra.to_doc(%Inspect.Opts{})
    |> Inspect.Algebra.format(50)
    |> Enum.join("")
  end

  defp create_config do
    %Credo.Execution{}
    |> Credo.Execution.SourceFiles.start_server()
    |> Credo.Execution.Issues.start_server()
    |> Credo.Execution.Timing.start_server()
  end

  defp get_issues_from_source_file(source_file, exec) do
    Issues.get(exec, source_file)
  end
end
