defmodule Credo.Check.Refactor.NegatedConditionsWithElseTest do
  use Credo.Test.Case

  @described_check Credo.Check.Refactor.NegatedConditionsWithElse

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        unless allowed? do
          something
        end
        if !allowed? do
          something
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
    defmodule Mix.Tasks.Credo do
      def run(argv) do
        if !allowed? do
          true
        else
          false
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation if used with parentheses" do
    """
    defmodule Mix.Tasks.Credo do
      def run(argv) do
        if (!allowed?) do
          true
        else
          false
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation with not/2 as well" do
    """
    defmodule Mix.Tasks.Credo do
      def run(argv) do
        if not allowed? do
          true
        else
          false
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end
end
