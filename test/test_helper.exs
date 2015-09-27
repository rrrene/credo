ExUnit.start()

defmodule Credo.TestHelper do
  defmacro __using__(_) do
    quote do
      use ExUnit.Case
      import CredoSourceFileCase
      import CredoRuleCase
    end
  end
end

defmodule CredoSourceFileCase do
  def to_source_file(source, filename \\ "untitled.ex") do
    case Credo.SourceFile.parse(source, filename) do
      %{valid?: true} = source_file -> source_file
      _ -> raise "Source could not be parsed!"
    end
  end
end

defmodule CredoRuleCase do
  use ExUnit.Case

  def refute_issues(source_file, rule \\ nil, config \\ []) do
    issues = issues_for(source_file, rule, config)
    assert [] == issues, "There should be no issues."
    source_file
  end

  def assert_issue(source_file, callback) when is_function(callback) do
    assert_issue(source_file, nil, [], callback)
  end

  def assert_issue(source_file, rule \\ nil, config \\ [], callback \\ nil) do
    issues = issues_for(source_file, rule, config)
    assert Enum.count(issues) == 1, "There should be an issue."
    if callback, do: callback.(issues |> List.first)
    source_file
  end

  def assert_issues(source_file, rule \\ nil, config \\ [], callback \\ nil) do
    issues = issues_for(source_file, rule, config)
    assert Enum.count(issues) > 0, "There should be issues."
    assert Enum.count(issues) > 1, "There should be more than one issue."
    if callback, do: callback.(issues)
    source_file
  end

  defp issues_for(source_file, nil, _), do: source_file.errors
  defp issues_for(source_file, rule, config), do: rule.test(source_file, config)
end
