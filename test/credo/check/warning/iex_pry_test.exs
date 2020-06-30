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
    |> assert_issue()
  end
end
