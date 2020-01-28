defmodule Credo.Check.Refactor.NegatedIsNilTest do
  use Credo.TestHelper

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
    |> refute_issues(@described_check)
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
    |> assert_issue(@described_check)
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
    |> assert_issue(@described_check)
  end
end
