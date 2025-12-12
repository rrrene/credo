defmodule Credo.Check.Refactor.WithClausesTest do
  use Credo.Test.Case

  @described_check Credo.Check.Refactor.WithClauses

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    ~S'''
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
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report expected code /2" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        with :ok <- parameter1 do
          parameter2
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report calls to functions called \"with\"" do
    ~S'''
    def some_function(parameter1, parameter2) do
      with(parameter1, parameter2)
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation if the with doesn't start with <- clauses" do
    ~S'''
    def some_function(parameter1, parameter2) do
      with IO.puts("not a <- clause"),
           :ok <- parameter1 do
        parameter2
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation if the with doesn't end with <- clauses" do
    ~S'''
    def some_function(parameter1, parameter2) do
      with :ok <- parameter1,
           IO.puts("not a <- clause") do
        parameter2
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(%{line_no: 2, trigger: "with"})
  end
end
