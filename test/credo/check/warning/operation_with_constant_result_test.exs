defmodule Credo.Check.Warning.OperationWithConstantResultTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.OperationWithConstantResult

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun do
        x * 2
        Enum.reject(some_list, &is_nil/1)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report expected code with specs" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      @spec some() :: <<_::1, _::_*1>>
      def some(), do: <<1::1>>

      @spec other() :: <<_::_*1>>
      def other(), do: <<>>
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation for * 1" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun do
        x * 1
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "*"
    end)
  end

  test "it should report a violation for all defined operations" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun(x, y) do
        x * 1   # always returns x
        x * 0   # always returns 0
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues(fn [two, one] ->
      assert one.trigger == "*"
      assert one.line_no == 5
      assert one.column == 7

      assert two.trigger == "*"
      assert two.line_no == 6
      assert two.column == 7
    end)
  end
end
