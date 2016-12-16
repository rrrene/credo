defmodule Credo.Check.Readability.SpecsTest do
  use Credo.TestHelper

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
    """ |> to_source_file()
        |> refute_issues(@described_check)
  end

  test "it should NOT report private functions" do
    """
    defmodule CredoTypespecTest do
      @spec foo(integer) :: integer
      def foo(a), do: a

      defp foo(a, b), do: a + b
    end
    """ |> to_source_file()
        |> refute_issues(@described_check)
  end

  test "it should report functions without specs" do
    """
    defmodule CredoTypespecTest do
      @spec foo(integer) :: integer
      def foo(a), do: a

      def foo(a, b), do: a + b
    end
    """ |> to_source_file()
        |> assert_issue(@described_check)
  end

  test "it should report specs with mismatched arity" do
    """
    defmodule CredoTypespecTest do
      @spec foo(integer) :: integer
      def foo(a), do: a

      def foo(a, b), do: a + b
    end
    """ |> to_source_file()
        |> assert_issue(@described_check)
  end
end
