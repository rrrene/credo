defmodule Credo.Check.Readability.SpecsTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.Specs

  #
  # cases NOT raising issues
  #

  test "it should NOT report functions with specs" do
    ~S'''
    defmodule CredoTypespecTest do
      @spec foo(integer, integer) :: integer
      @doc "some docs for foo/2"
      def foo(a, b), do: a + b

      @spec foo(integer) :: integer
      def foo(a), do: a
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report functions with specs containing a `when` clause" do
    ~S'''
    defmodule CredoTypespecTest do
      @spec foo(a, a) :: a when a: integer
      @doc "some docs for foo/2"
      def foo(a, b), do: a + b
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report private functions by default" do
    ~S'''
    defmodule CredoTypespecTest do
      @spec foo(integer) :: integer
      def foo(a), do: a

      defp foo(a, b), do: a + b
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report private functions with specs when enabled" do
    ~S'''
    defmodule CredoTypespecTest do
      @spec foo(integer) :: integer
      def foo(a), do: a

      @spec foo(integer) :: integer
      defp foo(a), do: a
    end
    '''
    |> to_source_file()
    |> run_check(@described_check, include_defp: true)
    |> refute_issues()
  end

  test "it should NOT report functions with guards and `@impl true`" do
    ~S'''
    defmodule CredoTypespecTest do
      @impl true
      def foo(a) when is_integer(a), do: a
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report functions without arguments and `@impl true`" do
    ~S'''
    defmodule CredoTypespecTest do
      @impl true
      def foo, do: :ok
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report functions with `@impl SomeMod`" do
    ~S'''
    defmodule CredoTypespecTest do
      @impl SomeMod
      def foo(a), do: a
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report function with arity zero and a spec with no parentheses" do
    ~S'''
    defmodule CredoTypespecTest do
      @spec foo :: :ok
      def foo, do: :ok
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report functions with `@impl true`" do
    ~S'''
    defmodule CredoTypespecTest do
      @impl true
      def foo(a), do: a
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report functions inside `quote`" do
    ~S'''
    @spec to_def(t(), atom()) :: Macro.t()
    def to_def(%__MODULE__{vars: vars, code: code}, name) do
      quote generated: true do
        def unquote(name)(unquote_splicing(vars)) do
          unquote(code)
        end
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report specs on private functions when enabled" do
    ~S'''
    defmodule CredoTypespecTest do
      @spec foo(integer) :: integer
      def foo(a), do: a

      defp foo(a, b), do: a + b
    end
    '''
    |> to_source_file()
    |> run_check(@described_check, include_defp: true)
    |> assert_issue()
  end

  test "it should report functions without specs" do
    ~S'''
    defmodule CredoTypespecTest do
      @spec foo(integer) :: integer
      def foo(a), do: a

      def foo(a, b), do: a + b
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report specs with mismatched arity" do
    ~S'''
    defmodule CredoTypespecTest do
      @spec foo(integer) :: integer
      def foo(a), do: a

      def foo(a, b), do: a + b
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report functions with `@impl false`" do
    ~S'''
    defmodule CredoTypespecTest do
      @impl false
      def foo(a), do: a
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report function with arity zero and no parentheses" do
    ~S'''
    defmodule CredoTypespecTest do
      def foo, do: :ok
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "foo"
    end)
  end

  test "it should report/not crash for unquote/1 calls in the function name" do
    ~S'''
    defmodule SpecIssue do
      function_name = :do_something

      def unquote(function_name)() do
        :ok
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "unquote(function_name)"
    end)
  end
end
