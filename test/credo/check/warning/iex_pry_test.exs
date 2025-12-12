defmodule Credo.Check.Warning.IExPryTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.IExPry

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        parameter1 + parameter2
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

  test "it should report a violation" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        x = parameter1 + parameter2
        IEx.pry
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(%{line_no: 4, trigger: "IEx.pry"})
  end

  test "it should report a violation with two on the same line" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        IEx.pry(); IEx.pry()
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues(2)
    |> assert_issues_match([
      %{line_no: 3, column: 5},
      %{line_no: 3, column: 16}
    ])
  end
end
