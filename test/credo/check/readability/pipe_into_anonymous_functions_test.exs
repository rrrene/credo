defmodule Credo.Check.Readability.PipeIntoAnonymousFunctionsTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.PipeIntoAnonymousFunctions

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    ~S'''
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun do
        some_val
        |> do_something
        |> do_something_else
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
      use ExUnit.Case

      def some_fun do
        some_val
        |> (fn x -> x * 2 end).()
        |> do_something
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "|>"
    end)
  end

  test "it should report a violation for multiple violations" do
    ~S'''
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun do
        some_val
        |> (fn x -> x * 2 end).()
        |> (fn x -> x * 2 end).()
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues()
  end
end
