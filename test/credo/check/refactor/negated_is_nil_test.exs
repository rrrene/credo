defmodule Credo.Check.Refactor.NegatedIsNilTest do
  use Credo.Test.Case

  @described_check Credo.Check.Refactor.NegatedIsNil

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, nil) do
        something
      end
      def some_function(parameter1, parameter2) do
        something
      end
      # `is_nil` in guard still works
      def common_guard(%{a: a, b: b}) when is_nil(b) do
        something
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation - `when not is_nil`" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) when not is_nil(parameter2) do
        something
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation - `when !is_nil`" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) when !is_nil(parameter2) do
        something
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end
end
