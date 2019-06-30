defmodule Credo.Check.Readability.ParenthesesOnZeroArityDefsTest do
  use Credo.TestHelper

  @described_check Credo.Check.Readability.ParenthesesOnZeroArityDefs

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        parameter1 + parameter2
      end

      def some_other_function do
        defp = 18
      end
    end
    """
    |> to_source_file
    |> refute_issues(@described_check)
  end

  #
  # cases raising issues
  #

  test "it should report a violation with parens (by default)" do
    """
    defmodule Mix.Tasks.Credo do
      def run() do
        21
      end
    end
    """
    |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation with no parens if parens: true" do
    """
    defmodule Mix.Tasks.Credo do
      def run do
        21
      end
    end
    """
    |> to_source_file
    |> assert_issue(@described_check, [parens: true], _callback = nil)
  end

  test "it should not crash on macros creating zero arity functions" do
    """
    defmodule Credo.Sample.Module do
      defmacro dynamic_methoder(attribute, value) do
        quote do
          def unquote(attribute)(), do: unquote(value)
        end
      end
    end
    """
    |> to_source_file
    |> refute_issues(@described_check)
  end
end
