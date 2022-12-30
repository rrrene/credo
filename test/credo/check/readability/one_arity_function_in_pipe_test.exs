defmodule Credo.Check.Readability.OneArityFunctionInPipeTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.OneArityFunctionInPipe

  test "it should report a violation for missing parentheses" do
    """
    defmodule Test do
      def some_function(arg) do
        arg
        |> foo()
        |> bar
        |> baz()
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report violations for missing parentheses" do
    """
    defmodule Test do
      def some_function(arg) do
        arg
        |> foo
        |> bar
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues()
  end

  test "it should NOT report violation for a valid pipe" do
    """
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
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation for a valid pipe with a block" do
    """
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
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end
end
