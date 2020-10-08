defmodule Credo.Check.Refactor.CondStatementsTest do
  use Credo.Test.Case

  @described_check Credo.Check.Refactor.CondStatements

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun do
        cond do
          x < x -> -1
          x == x -> 0
          true -> 1
        end

        cond do
          x < x -> -1
          x == x -> 0
          _ -> 1
        end

        cond do
          x < x -> -1
          x == x -> 0
          _named -> 1
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report expected code without an always true statement" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun do
        cond do
          x < x -> -1
          x == x -> 0
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
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun do
        cond do
          x == x -> 0
          true -> 1
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation for multiple violations" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun do
        cond do
          x == x -> 0
          true -> 1
        end
        cond do
          true -> 1
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues()
  end
end
