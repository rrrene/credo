defmodule Credo.Check.Refactor.IoPutsTest do
  use Credo.Test.Case

  @described_check Credo.Check.Refactor.IoPuts

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
        IO.puts parameter1 + parameter2
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation with two on the same line" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        IO.puts(parameter1); IO.puts(parameter2)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues(fn [two, one] ->
      assert one.line_no == 3
      assert one.column == 5
      assert two.line_no == 3
      assert two.column == 26
    end)
  end

  test "it should report a violation /2" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        parameter1 + parameter2
        |> IO.puts
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.line_no == 4
      assert issue.trigger == "IO.puts"
    end)
  end

  test "it should report a violation /3" do
    """
    defmodule CredoSampleModule do
      def some_function(a, b, c) do
        map([a,b,c], &IO.puts(&1))
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.line_no == 3
      assert issue.trigger == "IO.puts"
    end)
  end
end
