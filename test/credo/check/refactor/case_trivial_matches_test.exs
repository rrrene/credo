defmodule Credo.Check.Refactor.CaseTrivialMatchesTest do
  use Credo.Test.Case

  @described_check Credo.Check.Refactor.CaseTrivialMatches

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    defmodule Credo.Sample.Module do
      def some_function(p1, p2, p3, p4, p5) do
        case some_value do
          true -> :one
          false -> :three
          nil -> :four
          _ -> :something_else
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report expected code 2" do
    """
    defmodule Credo.Sample.Module do
      def some_function(p1, p2, p3, p4, p5) do
        case some_value do
          ^p1 -> :one
          ^p2 -> :two
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    """
    defmodule Credo.Sample.Module do
      def some_function(p1, p2, p3, p4, p5, p6) do
        case some_value do
          true -> :one
          false -> :three
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end
end
