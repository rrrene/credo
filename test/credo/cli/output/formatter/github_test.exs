defmodule Credo.CLI.Output.Formatter.GitHubTest do
  use Credo.Test.Case

  alias Credo.CLI.Output.Formatter.GitHub
  alias Credo.Issue

  setup do
    %{
      issue: %Issue{
        check: Credo.Check.Readability.ModuleDoc,
        category: :readability,
        priority: 1,
        message: "Modules should have a @moduledoc tag.",
        filename: "lib/foo.ex",
        line_no: 10,
        column: 5,
        trigger: Issue.no_trigger()
      }
    }
  end

  describe "to_annotation/1" do
    test "renders a warning for a normal priority issue", %{issue: %Issue{} = issue} do
      assert GitHub.to_annotation(issue) ==
               "::warning file=lib/foo.ex,line=10,col=5,title=Credo.Check.Readability.ModuleDoc::Modules should have a @moduledoc tag."
    end

    test "renders an error for high and higher priority issues", %{issue: %Issue{} = issue} do
      assert GitHub.to_annotation(%Issue{issue | priority: 12}) =~ ~r/^::error /
      assert GitHub.to_annotation(%Issue{issue | priority: 20}) =~ ~r/^::error /
    end

    test "renders a notice for low and ignored priority issues", %{issue: %Issue{} = issue} do
      assert GitHub.to_annotation(%Issue{issue | priority: -1}) =~ ~r/^::notice /
      assert GitHub.to_annotation(%Issue{issue | priority: -11}) =~ ~r/^::notice /
    end

    test "omits line and column properties when they are nil", %{issue: %Issue{} = issue} do
      assert GitHub.to_annotation(%Issue{issue | line_no: nil, column: nil}) ==
               "::warning file=lib/foo.ex,title=Credo.Check.Readability.ModuleDoc::Modules should have a @moduledoc tag."
    end

    test "includes endColumn when a trigger is present", %{issue: %Issue{} = issue} do
      assert GitHub.to_annotation(%Issue{issue | trigger: "@impl"}) ==
               "::warning file=lib/foo.ex,line=10,col=5,endColumn=10,title=Credo.Check.Readability.ModuleDoc::Modules should have a @moduledoc tag."
    end

    test "omits endColumn when column is nil", %{issue: %Issue{} = issue} do
      assert GitHub.to_annotation(%Issue{issue | column: nil, trigger: "@impl"}) ==
               "::warning file=lib/foo.ex,line=10,title=Credo.Check.Readability.ModuleDoc::Modules should have a @moduledoc tag."
    end

    test "escapes the message", %{issue: %Issue{} = issue} do
      assert GitHub.to_annotation(%Issue{issue | message: "50% of lines,\nare: too long\r\n"}) ==
               "::warning file=lib/foo.ex,line=10,col=5,title=Credo.Check.Readability.ModuleDoc::50%25 of lines,%0Aare: too long%0D%0A"
    end

    test "escapes property values", %{issue: %Issue{} = issue} do
      assert GitHub.to_annotation(%Issue{issue | filename: "lib/foo,bar:baz%.ex"}) ==
               "::warning file=lib/foo%2Cbar%3Abaz%25.ex,line=10,col=5,title=Credo.Check.Readability.ModuleDoc::Modules should have a @moduledoc tag."
    end
  end
end
