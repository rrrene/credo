defmodule Credo.Check.Readability.SpecsTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.Specs

  test "it should NOT report functions with specs" do
    """
    defmodule CredoTypespecTest do
      @spec foo(integer, integer) :: integer
      @doc "some docs for foo/2"
      def foo(a, b), do: a + b

      @spec foo(integer) :: integer
      def foo(a), do: a
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report functions with specs containing a `with` clause" do
    """
    defmodule CredoTypespecTest do
      @spec foo(a, a) :: a when a: integer
      @doc "some docs for foo/2"
      def foo(a, b), do: a + b
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report private functions" do
    """
    defmodule CredoTypespecTest do
      @spec foo(integer) :: integer
      def foo(a), do: a

      defp foo(a, b), do: a + b
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should report functions without specs" do
    """
    defmodule CredoTypespecTest do
      @spec foo(integer) :: integer
      def foo(a), do: a

      def foo(a, b), do: a + b
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report specs with mismatched arity" do
    """
    defmodule CredoTypespecTest do
      @spec foo(integer) :: integer
      def foo(a), do: a

      def foo(a, b), do: a + b
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should NOT report functions with `@impl true`" do
    """
    defmodule CredoTypespecTest do
      @impl true
      def foo(a), do: a
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report functions with guards and `@impl true`" do
    """
    defmodule CredoTypespecTest do
      @impl true
      def foo(a) when is_integer(a), do: a
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report functions without arguments and `@impl true`" do
    """
    defmodule CredoTypespecTest do
      @impl true
      def foo, do: :ok
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report functions with `@impl SomeMod`" do
    """
    defmodule CredoTypespecTest do
      @impl SomeMod
      def foo(a), do: a
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should report functions with `@impl false`" do
    """
    defmodule CredoTypespecTest do
      @impl false
      def foo(a), do: a
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report function with arity zero and no parentheses" do
    """
    defmodule CredoTypespecTest do
      def foo, do: :ok
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should NOT report function with arity zero and a spec with no parentheses" do
    """
    defmodule CredoTypespecTest do
      @spec foo :: :ok
      def foo, do: :ok
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end
end
