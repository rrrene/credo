Code.require_file("support/test_application.exs", __DIR__)

Credo.Test.Application.start([], [])

ExUnit.start()

# Exclude all external tests from running
ExUnit.configure(exclude: [to_be_implemented: true])

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
    filename = FilenameGenerator.next
    case Credo.SourceFile.parse(source, filename) do
      %{valid?: true} = source_file -> source_file
      _ -> raise "Source could not be parsed!"
    end
  end

  def to_source_files(list) do
    list
    |> Enum.map(&to_source_file/1)
  end
end

defmodule CredoCheckCase do
  use ExUnit.Case

  def refute_issues(source_file, check \\ nil, config \\ []) do
    issues = issues_for(source_file, check, config)
    assert [] == issues, "There should be no issues, got #{Enum.count(issues)}: #{to_inspected(issues)}"
    issues
  end

  def assert_issue(source_file, callback) when is_function(callback) do
    assert_issue(source_file, nil, [], callback)
  end
  def assert_issue(source_file, check, callback) when is_function(callback) do
    assert_issue(source_file, check, [], callback)
  end

  def assert_issue(source_file, check \\ nil, config \\ [], callback \\ nil) do
    issues = issues_for(source_file, check, config)
    refute Enum.count(issues) == 0, "There should be an issue."
    assert Enum.count(issues) == 1, "There should be only 1 issue, got #{Enum.count(issues)}: #{to_inspected(issues)}"
    if callback, do: callback.(issues |> List.first)
    issues
  end

  def assert_issues(source_file, callback) when is_function(callback) do
    assert_issues(source_file, nil, [], callback)
  end
  def assert_issues(source_file, check, callback) when is_function(callback) do
    assert_issues(source_file, check, [], callback)
  end
  def assert_issues(source_file, check \\ nil, config \\ [], callback \\ nil) do
    issues = issues_for(source_file, check, config)
    assert Enum.count(issues) > 0, "There should be issues, got none."
    assert Enum.count(issues) > 1, "There should be more than one issue, got: #{to_inspected(issues)}"
    if callback, do: callback.(issues)
    issues
  end

  defp issues_for(source_files, nil, _) when is_list(source_files) do
    source_files
    |> Enum.flat_map(&(&1.issues))
  end
  defp issues_for(source_files, check, config) when is_list(source_files) do
    source_files
    |> check.run(config)
    |> Enum.flat_map(&(&1.issues))
  end
  defp issues_for(source_file, nil, _), do: source_file.issues
  defp issues_for(source_file, check, config), do: check.run(source_file, config)


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
end
