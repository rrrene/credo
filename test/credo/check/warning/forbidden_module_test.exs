defmodule Credo.Check.Warning.ForbiddenModuleTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.ForbiddenModule

  #
  # cases NOT raising issues
  #

  test "it should NOT report with default params" do
    ~S'''
    defmodule CredoReplicateIssue do
      alias __MODULE__.Module

      def hello do
        Module.hello()
      end
    end

    defmodule CredoReplicateIssue.Module do
      def hello, do: :world
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report with default params /2" do
    ~S'''
    defmodule CredoSampleModule do
      alias CredoSampleModule.ForbiddenModule
      def some_function, do: ForbiddenModule.another_function()
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report on inline fully qualified usage" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function, do: CredoSampleModule.ForbiddenModule.another_function()
    end
    '''
    |> to_source_file
    |> run_check(@described_check, modules: [CredoSampleModule.ForbiddenModule])
    |> assert_issue(%{line_no: 2, column: 26})
  end

  test "it should report on aliases" do
    ~S'''
    defmodule CredoSampleModule do
      alias CredoSampleModule.ForbiddenModule
      def some_function, do: ForbiddenModule.another_function()
    end
    '''
    |> to_source_file
    |> run_check(@described_check, modules: [CredoSampleModule.ForbiddenModule])
    |> assert_issue(%{line_no: 2, column: 9})
  end

  test "it should report on grouped aliases" do
    ~S'''
    defmodule CredoSampleModule do
      alias CredoSampleModule.{AllowedModule, ForbiddenModule, ForbiddenModule2}
      def some_function, do: ForbiddenModule.another_function()
    end
    '''
    |> to_source_file
    |> run_check(@described_check,
      modules: [CredoSampleModule.ForbiddenModule, CredoSampleModule.ForbiddenModule2]
    )
    |> assert_issues(2)
    |> assert_issues_match([
      %{line_no: 2, column: 43, trigger: "ForbiddenModule"},
      %{line_no: 2, column: 60, trigger: "ForbiddenModule2"}
    ])
  end

  test "it should report on import" do
    ~S'''
    defmodule CredoSampleModule do
      import CredoSampleModule.ForbiddenModule
      def some_function, do: another_function()
    end
    '''
    |> to_source_file
    |> run_check(@described_check, modules: [CredoSampleModule.ForbiddenModule])
    |> assert_issue()
  end

  test "it should report on import only" do
    ~S'''
    defmodule CredoSampleModule do
      import CredoSampleModule.ForbiddenModule, only: [another_function: 0]
      def some_function, do: another_function()
    end
    '''
    |> to_source_file
    |> run_check(@described_check, modules: [CredoSampleModule.ForbiddenModule])
    |> assert_issue()
  end

  test "it should display a custom message" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function, do:
        CredoSampleModule.ForbiddenModule.another_function()
    end
    '''
    |> to_source_file
    |> run_check(@described_check, modules: [{CredoSampleModule.ForbiddenModule, "my message"}])
    |> assert_issue(%{message: "my message"})
  end

  test "it should work with multiple forbidden modules" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function, do: CredoSampleModule.ForbiddenModule.another_function()
      def some_function2, do: CredoSampleModule.ForbiddenModule2.another_function()
    end
    '''
    |> to_source_file
    |> run_check(@described_check,
      modules: [CredoSampleModule.ForbiddenModule, CredoSampleModule.ForbiddenModule2]
    )
    |> assert_issues()
  end
end
