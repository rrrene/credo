defmodule Credo.Check.Readability.ParenthesesOnZeroArityDefsTest do
  use Credo.Test.Case

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
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report expected code /2" do
    """
    defmodule Mix.Tasks.Credo do
      def foo!, do: impl().foo!()
      def foo?, do: impl().foo?()
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation with no parens if parens: true" do
    """
    defmodule Mix.Tasks.Credo do
      def good?() do
        :ok
      end

      def bang!() do
        :nok
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check, parens: true)
    |> refute_issues()
  end

  test "it should NOT report a violation with no parens if parens: true /2" do
    """
    defmodule Mix.Tasks.Credo do
      def foo!, do: impl().foo!()
      def foo?, do: impl().foo?()
    end
    """
    |> to_source_file
    |> run_check(@described_check, parens: true)
    |> assert_issues()
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
    |> run_check(@described_check)
    |> assert_issue()
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
    |> run_check(@described_check, parens: true)
    |> assert_issue()
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
    |> run_check(@described_check)
    |> refute_issues()
  end
end
