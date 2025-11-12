defmodule Credo.Check.Refactor.ApplyTest do
  use Credo.Test.Case

  @described_check Credo.Check.Refactor.Apply

  #
  # cases NOT raising issues
  #

  test "it should NOT report violation for apply/2" do
    ~S'''
    defmodule Test do
      def some_function(fun, args) do
        apply(fun, args)
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation for apply/2 when args returnded by a function" do
    ~S'''
    defmodule Test do
      def some_function(fun, args) do
        apply(fun, Enum.reverse(args))
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation for apply/2 when prepend args" do
    ~S'''
    defmodule Test do
      def some_function(fun, args) do
        apply(fun, [:foo | args])
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()

    ~S'''
    defmodule Test do
      def some_function(fun, args) do
        apply(fun, [:foo, :bar | args])
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation for apply/3" do
    ~S'''
    defmodule Test do
      def some_function(module, fun, args) do
        apply(module, fun, args)
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation for apply/3 when args returned by a function" do
    ~S'''
    defmodule Test do
      def some_function(module, fun, args) do
        apply(module, fun, Enum.reverse(args))
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation for apply/3 when prepend args" do
    ~S'''
    defmodule Test do
      def some_function(module, fun, args) do
        apply(module, fun, [:foo | args])
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()

    ~S'''
    defmodule Test do
      def some_function(module, fun, args) do
        apply(module, fun, [:foo, :bar | args])
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation for apply/3 when called with __MODULE__" do
    ~S'''
    defmodule Test do
      def some_function do
        apply(__MODULE__, :foo, [])
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation for apply/3 when fun is a var" do
    ~S'''
    defmodule Test do
      def some_function(module, fun, arg1, arg2) do
        apply(module, fun, [arg1, arg2])
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation for piped apply/3 when fun is a var" do
    ~S'''
    defmodule Test do
      def some_function(module, fun, arg1, arg2) do
        module
        |> apply(fun1, [arg1, arg2])
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation for apply/3 when fun is a function" do
    ~S'''
    defmodule Test do
      def some_function(module, fun, arg1, arg2) do
        apply(module, String.to_exisiting_atom("pre_#{fun}"), [arg1, arg2])
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation for apply/3 when args is a var" do
    ~S'''
    defmodule Test do
      def some_function(args) when is_list(args) do
        apply(Module, :fun, args)
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation for apply/2 when defining local apply/2" do
    ~S'''
    defmodule Test do
      @spec apply(fun, [any]) :: any
      def apply(fun, args) do
        :erlang.apply(fun, args)
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

  test "it should report violation for apply/2 in a pipe" do
    ~S'''
    defmodule Test do
      def some_function(fun, arg1, arg2) do
        fun2 |> apply([arg1, arg2])
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation for apply/3 in a pipe" do
    ~S'''
    defmodule Test do
      def some_function(module, arg1, arg2) do
        module |> apply(:fun_name3, [arg1, arg2])
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report violation for apply/2" do
    ~S'''
    defmodule Test do
      def some_function(fun, arg1, arg2) do
        apply(fun, [arg1, arg2])
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation for apply/3" do
    ~S'''
    defmodule Test do
      def some_function(module, arg1, arg2) do
        apply(module, :fun_name, [arg1, arg2])
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "apply"
    end)
  end
end
