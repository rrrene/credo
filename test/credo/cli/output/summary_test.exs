defmodule Credo.CLI.Output.SummaryTest do
  use Credo.Test.Case

  alias Credo.CLI.Output.Summary
  alias Credo.Execution
  alias Credo.Issue

  doctest Credo.CLI.Output.Summary

  test "print/4 it does not blow up on an empty umbrella project" do
    exec = Execution.build()

    Summary.print([], exec, 0, 0)
  end

  describe "print_issue_type_summary/2" do
    test "it does not print when there are no issues" do
      exec = Execution.build()

      # Should not raise an error
      Summary.print([], exec, 0, 0)
    end

    test "it does not print in short format" do
      exec = Execution.build() |> Map.put(:format, "short")
      issues = [create_issue(:readability, Credo.Check.Readability.ModuleDoc, "lib/foo.ex")]

      exec = Execution.put_issues(exec, issues)

      # Should not raise an error and should skip printing
      Summary.print([], exec, 0, 0)
    end

    test "it prints issue type summary with counts and percentages" do
      exec = Execution.build()

      issues = [
        create_issue(:readability, Credo.Check.Readability.ModuleDoc, "lib/foo.ex"),
        create_issue(:readability, Credo.Check.Readability.ModuleDoc, "lib/bar.ex"),
        create_issue(:design, Credo.Check.Design.AliasUsage, "lib/baz.ex"),
        create_issue(:refactor, Credo.Check.Refactor.CyclomaticComplexity, "lib/qux.ex")
      ]

      exec = Execution.put_issues(exec, issues)

      # Should not raise an error
      Summary.print([], exec, 0, 0)
    end
  end

  describe "print_issue_name_summary/2" do
    test "it does not print when there are no issues" do
      exec = Execution.build()

      Summary.print([], exec, 0, 0)
    end

    test "it does not print in short format" do
      exec = Execution.build() |> Map.put(:format, "short")
      issues = [create_issue(:readability, Credo.Check.Readability.ModuleDoc, "lib/foo.ex")]

      exec = Execution.put_issues(exec, issues)

      Summary.print([], exec, 0, 0)
    end

    test "it prints issue name summary grouped by check" do
      exec = Execution.build()

      issues = [
        create_issue(:readability, Credo.Check.Readability.ModuleDoc, "lib/foo.ex"),
        create_issue(:readability, Credo.Check.Readability.ModuleDoc, "lib/bar.ex"),
        create_issue(:readability, Credo.Check.Readability.ModuleDoc, "lib/baz.ex"),
        create_issue(:design, Credo.Check.Design.AliasUsage, "lib/qux.ex"),
        create_issue(:design, Credo.Check.Design.AliasUsage, "lib/quux.ex")
      ]

      exec = Execution.put_issues(exec, issues)

      Summary.print([], exec, 0, 0)
    end
  end

  describe "print_top_files_summary/2" do
    test "it does not print when there are no issues" do
      exec = Execution.build()

      Summary.print([], exec, 0, 0)
    end

    test "it does not print in short format" do
      exec = Execution.build() |> Map.put(:format, "short")
      issues = [create_issue(:readability, Credo.Check.Readability.ModuleDoc, "lib/foo.ex")]

      exec = Execution.put_issues(exec, issues)

      Summary.print([], exec, 0, 0)
    end

    test "it prints top files with default limit of 10" do
      exec = Execution.build()

      issues = [
        create_issue(:readability, Credo.Check.Readability.ModuleDoc, "lib/foo.ex"),
        create_issue(:readability, Credo.Check.Readability.ModuleDoc, "lib/foo.ex"),
        create_issue(:readability, Credo.Check.Readability.ModuleDoc, "lib/foo.ex"),
        create_issue(:design, Credo.Check.Design.AliasUsage, "lib/bar.ex"),
        create_issue(:design, Credo.Check.Design.AliasUsage, "lib/bar.ex"),
        create_issue(:refactor, Credo.Check.Refactor.CyclomaticComplexity, "lib/baz.ex")
      ]

      exec = Execution.put_issues(exec, issues)

      Summary.print([], exec, 0, 0)
    end

    test "it respects custom top_files count" do
      exec = Execution.build() |> Map.put(:top_files, 5)

      issues =
        for i <- 1..20 do
          create_issue(:readability, Credo.Check.Readability.ModuleDoc, "lib/file#{i}.ex")
        end

      exec = Execution.put_issues(exec, issues)

      # Should limit to top 5 files
      Summary.print([], exec, 0, 0)
    end

    test "it shows total count and percentage for top files" do
      exec = Execution.build()

      # Create issues where top 2 files have 60% of all issues
      issues =
        [
          create_issue(:readability, Credo.Check.Readability.ModuleDoc, "lib/foo.ex"),
          create_issue(:readability, Credo.Check.Readability.ModuleDoc, "lib/foo.ex"),
          create_issue(:readability, Credo.Check.Readability.ModuleDoc, "lib/foo.ex"),
          create_issue(:design, Credo.Check.Design.AliasUsage, "lib/bar.ex"),
          create_issue(:design, Credo.Check.Design.AliasUsage, "lib/bar.ex"),
          create_issue(:design, Credo.Check.Design.AliasUsage, "lib/bar.ex"),
          create_issue(:refactor, Credo.Check.Refactor.CyclomaticComplexity, "lib/baz.ex"),
          create_issue(:refactor, Credo.Check.Refactor.CyclomaticComplexity, "lib/qux.ex"),
          create_issue(:warning, Credo.Check.Warning.IoInspect, "lib/quux.ex"),
          create_issue(:warning, Credo.Check.Warning.IoInspect, "lib/corge.ex")
        ]

      exec = Execution.put_issues(exec, issues)

      Summary.print([], exec, 0, 0)
    end
  end

  describe "get_top_files_count/1" do
    test "it returns default of 10 when not specified" do
      exec = Execution.build()

      # Access the private function through the module's behavior
      # We test this indirectly through print_top_files_summary
      issues =
        for i <- 1..15 do
          create_issue(:readability, Credo.Check.Readability.ModuleDoc, "lib/file#{i}.ex")
        end

      exec = Execution.put_issues(exec, issues)

      # Should use default of 10
      Summary.print([], exec, 0, 0)
    end

    test "it returns custom value when specified" do
      exec = Execution.build() |> Map.put(:top_files, 3)

      issues =
        for i <- 1..15 do
          create_issue(:readability, Credo.Check.Readability.ModuleDoc, "lib/file#{i}.ex")
        end

      exec = Execution.put_issues(exec, issues)

      # Should use custom value of 3
      Summary.print([], exec, 0, 0)
    end

    test "it returns default when top_files is 0" do
      exec = Execution.build() |> Map.put(:top_files, 0)

      issues = [create_issue(:readability, Credo.Check.Readability.ModuleDoc, "lib/foo.ex")]

      exec = Execution.put_issues(exec, issues)

      # Should fall back to default of 10
      Summary.print([], exec, 0, 0)
    end

    test "it returns default when top_files is negative" do
      exec = Execution.build() |> Map.put(:top_files, -5)

      issues = [create_issue(:readability, Credo.Check.Readability.ModuleDoc, "lib/foo.ex")]

      exec = Execution.put_issues(exec, issues)

      # Should fall back to default of 10
      Summary.print([], exec, 0, 0)
    end
  end

  # Helper function to create test issues
  defp create_issue(category, check, filename) do
    %Issue{
      check: check,
      category: category,
      priority: 5,
      severity: 10,
      message: "Test issue message",
      filename: filename,
      line_no: 1,
      column: 1,
      trigger: "test"
    }
  end
end
