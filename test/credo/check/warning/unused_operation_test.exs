defmodule Credo.Check.Warning.UnusedOperationTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.UnusedOperation

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        Map.from_struct!(opts)

        Map.values(parameter1) + parameter2
      end

      def invoke(task) when is_atom(task) do
        Enum.each(Map.get(MyAgent.get(:before_hooks), task, []),
          fn([module, fnref]) -> apply(module, fnref, []) end)
        Enum.each(Map.get(MyAgent.get(:after_hooks), task, []),
          fn([module, fnref]) -> apply(module, fnref, []) end)
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check,
      modules: [
        {:Map, [:get, :fetch]},
        {:Keywords, [:get, :fetch], "My special issue message"}
      ]
    )
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        x = parameter1 + parameter2

        Map.take(parameter1, x)

        parameter1
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check,
      modules: [
        {:Map, [:get, :take], "My special issue message"},
        {:Keywords, [:get, :fetch]}
      ]
    )
    |> assert_issue(%{message: ~r/special/})
  end
end
