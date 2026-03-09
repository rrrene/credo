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

      def other_function(param) do
        MyModule.transform(param)
      end

      def other_function do
        OtherModule.do_the_thing()
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check,
      modules: [
        {Map, [:get, :fetch]},
        {Keywords, [:get, :fetch], "My special issue message"},
        {MyModule, :all},
        {OtherModule, :all, "My special issue message"}
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
        {Map, [:get, :take], "My special issue message"},
        {Keywords, [:get, :fetch]}
      ]
    )
    |> assert_issue(%{trigger: "Map.take", message: ~r/special/})
  end

  test "it should report violations when using module-only config" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        MyModule.transform(parameter1)
        OtherModule.do_something(parameter3)

        :ok
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check,
      modules: [
        {MyModule, :all},
        {OtherModule, :all, "My special issue message"}
      ]
    )
    |> assert_issues(2)
    |> assert_issues_match([
      %{
        trigger: "MyModule.transform",
        message: ~r/`MyModule`/
      },
      %{
        trigger: "OtherModule.do_something",
        message: "My special issue message"
      }
    ])
  end
end
