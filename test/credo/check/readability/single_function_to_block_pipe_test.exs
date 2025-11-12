defmodule Credo.Check.Readability.SingleFunctionToBlockPipeTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.SingleFunctionToBlockPipe

  #
  # cases NOT raising issues
  #

  test "it should NOT report violation for valid pipes" do
    ~S'''
    defmodule Test do
      def some_function(arg) do
        arg
        |> do_something()
        |> do_something_else()
        |> case do
          :this -> :that
          :that -> :this
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation for valid pipes to if-expr" do
    ~S'''
    defmodule Test do
      def some_function(arg) do
        arg
        |> do_something()
        |> do_something_else()
        |> if do
          :that
        else
          :this
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation for longer pipes" do
    ~S'''
    defmodule Test do
      def some_function(arg) do
        arg
        |> do_something()
        |> case do
          :this -> :that
          :that -> :this
        end
        |> to_string()
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

  test "it should report violation for single pipes to block" do
    ~S'''
    defmodule Test do
      def some_function(arg) do
        arg
        |> case do
          :this -> :that
          :that -> :this
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "case"
    end)
  end

  test "it should report violation for single pipes to case with function" do
    ~S'''
    defmodule Test do
      def some_function(arg) do
        arg
        |> do_something()
        |> case do
          :this -> :that
          :that -> :this
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report violation for single pipes to if-expr with function" do
    ~S'''
    defmodule Test do
      def some_function(arg) do
        arg
        |> do_something()
        |> if do
          :that
        else
          :this
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report violation for single pipes starting with a list" do
    ~S'''
    defmodule Test do
      def some_function(arg) do
        [arg]
        |> do_something()
        |> case do
          :this -> :that
          :that -> :this
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report violation for single pipes starting with a map" do
    ~S'''
    defmodule Test do
      def some_function(arg) do
        %{a: 5}
        |> do_something()
        |> case do
          :this -> :that
          :that -> :this
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end
end
