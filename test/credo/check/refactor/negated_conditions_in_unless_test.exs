defmodule Credo.Check.Refactor.NegatedConditionsInUnlessTest do
  use Credo.Test.Case

  @described_check Credo.Check.Refactor.NegatedConditionsInUnless

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    ~S'''
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
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report expected code /2" do
    ~S'''
    defmodule CredoSampleModule do
      @unless !allowed?

      def some_fun do
        unless = 123
        :unless
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
        unless !allowed? do
          something
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.line_no == 3
      assert issue.trigger == "!"
    end)
  end

  test "it should report a violation with not" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        unless not allowed? do
          something
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.line_no == 3
      assert issue.trigger == "not"
    end)
  end
end
