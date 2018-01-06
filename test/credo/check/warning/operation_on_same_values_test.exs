defmodule Credo.Check.Warning.OperationOnSameValuesTest do
  use Credo.TestHelper

  @described_check Credo.Check.Warning.OperationOnSameValues

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun do
        assert x == x + 2
      end
    end
    """
    |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should NOT report operator definitions" do
    """
    defmodule Red do
      @moduledoc false
      @spec number - number :: number
      def a - a do
        a + 1
      end
    end
    """
    |> to_source_file
    |> refute_issues(@described_check)
  end

  #
  # cases raising issues
  #

  test "it should report a violation for ==" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun do
        assert x == x
      end
    end
    """
    |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation for module attributes" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case
      @a 5
      @some_module_attribute @a - @a
    end
    """
    |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation for all defined operations" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun do
        x == x  # always true
        x >= x  # always false
        x <= x  # always false
        x != x  # always false
        x > x   # always false
        y / y   # always 1
        y - y   # always 0
        y -
          y # on different lines
        y - y + x
      end
    end
    """
    |> to_source_file
    |> assert_issues(@described_check, fn issues ->
      assert 9 == Enum.count(issues)
    end)
  end
end
