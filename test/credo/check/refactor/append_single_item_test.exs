defmodule Credo.Check.Refactor.AppendSingleItemTest do
  use Credo.Test.Case

  @described_check Credo.Check.Refactor.AppendSingleItem

  #
  # cases NOT raising issues
  #

  test "it should NOT report appending 2 items" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        [parameter1] ++ [parameter2]
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report prepending an item" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        [parameter1] ++ parameter2
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report on 2 lists" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        parameter1 ++ parameter2
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report appending 2 items on a pre-existing list" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(list, parameter1, parameter2) do
        list ++ [parameter1, parameter2]
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        parameter1 ++ [parameter2]
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "++"
    end)
  end
end
