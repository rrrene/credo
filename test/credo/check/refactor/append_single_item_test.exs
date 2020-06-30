defmodule Credo.Check.Refactor.AppendSingleItemTest do
  use Credo.Test.Case

  @described_check Credo.Check.Refactor.AppendSingleItem

  test "it should NOT report appending 2 items" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        [parameter1] ++ [parameter2]
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report prepending an item" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        [parameter1] ++ parameter2
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report on 2 lists" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        parameter1 ++ parameter2
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report appending 2 items on a pre-existing list" do
    """
    defmodule CredoSampleModule do
      def some_function(list, parameter1, parameter2) do
        list ++ [parameter1, parameter2]
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should report a violation" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        parameter1 ++ [parameter2]
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end
end
