defmodule Credo.Check.Consistency.CollectorTest do
  use Credo.Test.Case

  alias Credo.Check.Consistency.Collector
  alias Credo.SourceFile

  defmodule TestCollector do
    def collect_matches(source_file, _params) do
      case SourceFile.source(source_file) do
        ":mostly_foo" -> %{foo: 2}
        ":only_bar" -> %{bar: 1}
        ":mostly_bar" -> %{bar: 2}
      end
    end
  end

  test "reports files containing matches other than the unique most frequent match" do
    source_files = source_files([":mostly_foo", ":only_bar"])

    assert [%{expected: :foo, filename: "bar.ex"}] = find_issues(source_files)
  end

  test "does not report issues when the most frequent matches are tied" do
    source_files = source_files([":mostly_foo", ":mostly_bar"])

    assert [] == find_issues(source_files)
  end

  test "reports matches that differ from a forced convention when frequencies are tied" do
    source_files = source_files([":mostly_foo", ":mostly_bar"])

    assert [%{expected: :foo, filename: "bar.ex"}] = find_issues(source_files, force: :foo)
  end

  defp find_issues(source_files, params \\ []) do
    issue_formatter = fn expected, source_file, _params ->
      [%{expected: expected, filename: source_file.filename}]
    end

    Collector.find_issues(source_files, TestCollector, params, issue_formatter, false)
  end

  defp source_files([foo, bar]) do
    [to_source_file(foo, "foo.ex"), to_source_file(bar, "bar.ex")]
  end
end
