defmodule Credo.Check.Readability.OneArityFunctionInPipeTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.OneArityFunctionInPipe

  #
  # cases NOT raising issues
  #

  test "it should NOT report violation for a valid pipe" do
    ~S'''
    defmodule Test do
      def some_function(arg) do
        arg |> foo() |> bar()
      end

      def other_function(arg) do
        arg
        |> foo()
        |> bar()
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation for a valid pipe with a block" do
    ~S'''
    defmodule Test do
      def other_function(arg) do
        arg
        |> foo()
        |> case do
          :x -> :y
          :u -> :u
        end
        |> bar()
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

  test "it should report a violation for missing parentheses" do
    ~S'''
    defmodule Test do
      def some_function(arg) do
        arg
        |> foo()
        |> bar
        |> baz()
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "bar"
    end)
  end

  test "it should report violations for missing parentheses" do
    ~S'''
    defmodule Test do
      def some_function(arg) do
        arg
        |> foo
        |> bar
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues()
  end
end
