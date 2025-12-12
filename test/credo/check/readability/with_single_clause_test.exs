defmodule Credo.Check.Readability.WithSingleClauseTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.WithSingleClause

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

  test "it should NOT report when using unquote_splicing" do
    ~S'''
    quote do
      with unquote_splicing(cases) do
        {:ok, unquote(ret)}
      else
        _ -> :error
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

  test "it should report a violation for a single <- clause if there's an else branch" do
    ~S'''
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
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(%{line_no: 3, trigger: "with"})
  end
end
