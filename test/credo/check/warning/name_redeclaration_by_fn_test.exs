defmodule Credo.Check.Warning.NameRedeclarationByFnTestTest do
  use Credo.TestHelper

  @described_check Credo.Check.Warning.NameRedeclarationByFn

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def fun1 do
        case fun2 do
          x -> x
          %{something: foobar} -> foobar
        end
        [a, b, 42] = fun2
        %{a: a, b: b, c: false} = fun2
        %SomeModule{a: a, b: b, c: false} = fun2

        fun2 + 1
      end

      defmacro fun2 do
        42
      end
    end
    """
    |> to_source_file
    |> refute_issues(@described_check)
  end

  #
  # cases raising issues
  #

  test "it should report a violation when a variable is declared with the same name as a function" do
    """
    defmodule CredoSampleModule do
      def fun1(p1) do
        Enum.map(p1, fn
          {a, a} ->
            IO.inspect a
          {x, fun2} ->
            IO.inspect fun2       # now the variable is used instead of the function
        end)
      end

      def fun2 do
        42
      end
    end
    """
    |> to_source_file
    |> assert_issue(@described_check)
  end
end
