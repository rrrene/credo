defmodule Credo.Check.Readability.MissingTypespecsTest do
  use Credo.TestHelper

  @described_check Credo.Check.Readability.MissingTypespecs

  test "it should NOT report functions with specs" do
    """
    defmodule CredoTypespecTest do
      @spec foo(integer, integer) :: integer
      def foo(a, b), do: a + b
    end
    """ |> to_source_file()
        |> refute_issues(@described_check)
  end

  test "it should NOT report private functions" do
    """
    defmodule CredoTypespecTest do
      defp foo(a, b), do: a + b
    end
    """ |> to_source_file()
        |> refute_issues(@described_check)
  end

  test "it should report functions without specs" do
    """
    defmodule CredoTypespecTest do
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
