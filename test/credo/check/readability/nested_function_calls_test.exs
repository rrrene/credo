defmodule Credo.Check.Readability.NestedFunctionCallsTest do
  use Credo.Test.Case

  alias Credo.Check.Readability.NestedFunctionCalls

  test "it should NOT code with no nested function calls" do
    """
    defmodule CredoSampleModule do
      def some_code do
        Enum.shuffle([1,2,3])
      end
    end
    """
    |> to_source_file()
    |> run_check(NestedFunctionCalls)
    |> refute_issues()
  end

  test "it should NOT report string interpolation" do
    """
    defmodule CredoSampleModule do
      def some_code do
        "Take 10 #{Enum.take([1,2,2,3,3], 10)}"
      end
    end
    """
    |> to_source_file()
    |> run_check(NestedFunctionCalls)
    |> refute_issues()
  end

  test "it should NOT report Access protocol lookups" do
    """
    defmodule CredoSampleModule do
      def some_code do
        Enum.take(map[:some_key])
      end
    end
    """
    |> to_source_file()
    |> run_check(NestedFunctionCalls)
    |> refute_issues()
  end

  test "it should NOT two nested functions calls when the inner function call takes no arguments" do
    """
    defmodule CredoSampleModule do
      def some_code do
        Enum.uniq(some_list())
      end
    end
    """
    |> to_source_file()
    |> run_check(NestedFunctionCalls)
    |> refute_issues()
  end

  test "it should report two nested functions calls when the inner call receives some arguments" do
    """
    defmodule CredoSampleModule do
      def some_code do
        Enum.shuffle(Enum.uniq([1,2,2,3,3]))
      end
    end
    """
    |> to_source_file()
    |> run_check(NestedFunctionCalls)
    |> assert_issue()
  end

  test "it should report three nested functions calls" do
    """
    defmodule CredoSampleModule do
      def some_code do
        Enum.shuffle(Enum.uniq(Enum.take([1,2,2,3,3], 10)))
      end
    end
    """
    |> to_source_file()
    |> run_check(NestedFunctionCalls)
    |> assert_issues()
  end

  test "it should report two nested functions calls when min_pipeline_length is set to one" do
    """
    defmodule CredoSampleModule do
      def some_code do
        Enum.uniq(some_list())
      end
    end
    """
    |> to_source_file()
    |> run_check(NestedFunctionCalls, min_pipeline_length: 1)
    |> assert_issue()
  end

  test "it should NOT report two nested functions calls with arguments when min_pipeline_length is set to three" do
    """
    defmodule CredoSampleModule do
      def some_code do
        Enum.shuffle(Enum.uniq([1,2,2,3,3]))
      end
    end
    """
    |> to_source_file()
    |> run_check(NestedFunctionCalls, min_pipeline_length: 3)
    |> refute_issues()
  end
end
