defmodule Credo.CLI.Output.Formatter.Codeclimate do
  alias Credo.CLI.Filename
  alias Credo.CLI.Output
  alias Credo.CLI.Output.UI
  alias Credo.Issue

  @issue_category %{
    Credo.Check.Design.DuplicatedCode => ["Duplication"],
    Credo.Check.Readability.ModuleDoc => ["Clarity"],
    Credo.Check.Readability.ModuleNames => ["Clarity"],
    Credo.Check.Refactor.ABCSize => ["Complexity"],
    Credo.Check.Refactor.CyclomaticComplexity => ["Complexity"],
    Credo.Check.Warning.NameRedeclarationByFn => ["Clarity"],
    Credo.Check.Warning.OperationOnSameValues => ["Bug Risk"],
    Credo.Check.Warning.BoolOperationOnSameValues => ["Bug Risk"],
    Credo.Check.Warning.UnusedEnumOperation => ["Bug Risk"],
    Credo.Check.Warning.UnusedKeywordOperation => ["Bug Risk"],
    Credo.Check.Warning.UnusedListOperation => ["Bug Risk"],
    Credo.Check.Warning.UnusedStringOperation => ["Bug Risk"],
    Credo.Check.Warning.UnusedTupleOperation => ["Bug Risk"],
    Credo.Check.Warning.OperationWithConstantResult => ["Bug Risk"]
  }

  def print_issues(issues) do
    issues
    |> Enum.map(&to_json/1)
    |> Enum.join("\0")
    |> UI.puts()
  end

  def to_json(%Issue{
        check: check,
        message: message,
        line_no: line,
        column: column,
        filename: filename,
        priority: priority
      }) do
    %{
      type: "Issue",
      categories: categories(check),
      check_name: check_name(check),
      description: message,
      remediation_points: 50_000,
      severity: severity(priority),
      content: %{
        body: check.explanation
      },
      location: %{
        path: filename,
        lines: %{
          begin: %{
            line: line || 1,
            columnt: column || 1
          },
          end: %{
            line: line || 1,
            column: column || 1
          }
        }
      }
    }
    |> Jason.encode!()
  end

  defp categories(issue) do
    @issue_category[issue] || ["Style"]
  end

  defp check_name(issue) do
    issue
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
  end

  defp severity(priority) do
    case priority do
      priority when priority > 20 -> "blocker"
      priority when priority in 10..19 -> "critical"
      priority when priority in 0..9 -> "major"
      priority when priority in -10..-1 -> "minor"
      priority when priority < - 10 -> "info"
    end
  end
end
