defmodule Credo.Check.Refactor.WithClausesTest do
  use Credo.Test.Case

  @described_check Credo.Check.Refactor.WithClauses

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        with :ok <- parameter1,
             _ref = make_ref(),
             IO.puts("Imperative operation"),
             :ok <- parameter2 do
          :ok
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()

    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        with :ok <- parameter1 do
          parameter2
        end
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

  test "it should report a violation for a single <- clause if there's an else branch" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        with :ok <- parameter1 do
          parameter2
        else
          :error ->
            :error
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation if the with doesn't start with <- clauses" do
    """
    def some_function(parameter1, parameter2) do
      with IO.puts("not a <- clause"),
           :ok <- parameter1 do
        parameter2
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.message =~ ~s(doesn't start with a <- clause)
    end)
  end

  test "it should report a violation if the with doesn't end with <- clauses" do
    """
    def some_function(parameter1, parameter2) do
      with :ok <- parameter1,
           IO.puts("not a <- clause") do
        parameter2
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.message =~ ~s(doesn't end with a <- clause)
    end)
  end

  #
  # cases that should not be examined at all
  #

  test "it shouldn't check calls to functions called \"with\"" do
    """
    def some_function(parameter1, parameter2) do
      with(parameter1, parameter2)
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end
end
