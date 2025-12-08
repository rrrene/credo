defmodule Credo.Test.CheckRunnerTest do
  use ExUnit.Case, async: true

  import Credo.Test.CheckRunner
  import Credo.Test.Assertions

  alias Credo.Issue
  alias Credo.SourceFile

  @source_file %SourceFile{filename: "x"}

  defmodule FakeTestCheck do
    use Credo.Check

    def run(%SourceFile{} = source_file, params \\ []) do
      if params[:issue_count] do
        issue_count = params[:issue_count] || 0

        replicate(issue_count, %Issue{filename: source_file.filename})
      else
        []
      end
    end

    defp replicate(count, item) do
      for(_ <- 1..count, do: item)
    end
  end

  test "it should run the check" do
    @source_file
    |> run_check(FakeTestCheck, [])
    |> refute_issues()
  end

  test "it should run the check /2" do
    @source_file
    |> run_check(FakeTestCheck, issue_count: 1)
    |> assert_issue()
  end

  test "it should run the check /3" do
    @source_file
    |> run_check(FakeTestCheck, issue_count: 3)
    |> assert_issues(3)
  end
end
