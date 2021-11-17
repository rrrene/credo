defmodule Credo.Check.Refactor.RedundantWithClauseResultTest do
  use Credo.Test.Case

  @described_check Credo.Check.Refactor.RedundantWithClauseResult

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        with :ok <- parameter1,
             {:ok, val} <- parameter2 do
          val
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

    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        with :ok <- parameter1,
             {:ok, val} <- parameter2 do
          Logger.debug(inspect(val))
          {:ok, val}
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report if an else block is present" do
    """
    def some_function(parameter1, parameter2) do
      with :ok <- parameter1,
           :ok <- parameter2 do
        :ok
      else
        _ -> :error
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

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

  #
  # cases raising issues
  #

  test "it should report a violation if the last clause is redundant" do
    """
    def some_function(parameter1, parameter2) do
      with :ok <- parameter1,
           :ok <- parameter2 do
        :ok
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.message == "the last clause in `with` is redundant"
    end)
  end

  test "it should report a violation if the last clause expects same tuple as the with returns" do
    """
    def some_function(parameter1, parameter2) do
      with :ok <- parameter1,
           {:ok, val} <- check(parameter2) do
        {:ok, val}
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.message == "the last clause in `with` is redundant"
    end)
  end

  test "it should report a violation if the with is redundant" do
    """
    def some_function(parameter) do
      with {:ok, val} <- do_something(parameter) do
        {:ok, val}
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.message == "the `with` statement is redundant"
    end)
  end
end
