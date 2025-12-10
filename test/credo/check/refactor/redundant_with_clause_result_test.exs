defmodule Credo.Check.Refactor.RedundantWithClauseResultTest do
  use Credo.Test.Case

  @described_check Credo.Check.Refactor.RedundantWithClauseResult

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        with :ok <- parameter1,
             {:ok, val} <- parameter2 do
          val
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

    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        with :ok <- parameter1,
             {:ok, val} <- parameter2 do
          Logger.debug(inspect(val))
          {:ok, val}
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report if an else block is present" do
    ~S'''
    def some_function(parameter1, parameter2) do
      with :ok <- parameter1,
           :ok <- parameter2 do
        :ok
      else
        _ -> :error
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report clauses containing a map match" do
    ~S'''
    def test do
      with :ok <- check(),
          {:ok, %{id: id}} <- much_data() do
        {:ok, %{id: id}}
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

  test "it should report a violation if the last clause is redundant" do
    ~S'''
    def some_function(parameter1, parameter2) do
      with :ok <- parameter1,
           :ok <- parameter2 do
        :ok
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(%{
      line_no: 2,
      trigger: "with",
      message: "Last clause in `with` is redundant."
    })
  end

  test "it should report a violation if the last clause expects same tuple as the with returns" do
    ~S'''
    def some_function(parameter1, parameter2) do
      with :ok <- parameter1,
           {:ok, val} <- check(parameter2) do
        {:ok, val}
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(%{line_no: 2, message: "Last clause in `with` is redundant."})
  end

  test "it should report a violation if the with is redundant" do
    ~S'''
    def some_function(parameter) do
      with {:ok, val} <- do_something(parameter) do
        {:ok, val}
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(%{line_no: 2, message: "`with` statement is redundant."})
  end
end
