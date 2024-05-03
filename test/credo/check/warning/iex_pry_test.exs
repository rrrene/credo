defmodule Credo.Check.Warning.IExPryTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.IExPry

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        parameter1 + parameter2
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        x = parameter1 + parameter2
        IEx.pry
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.line_no == 4
      assert issue.trigger == "IEx.pry"
    end)
  end

  test "it should report a violation with two on the same line" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        IEx.pry(); IEx.pry()
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues(fn [two, one] ->
      assert one.line_no == 3
      assert one.column == 5
      assert two.line_no == 3
      assert two.column == 16
    end)
  end
end
