defmodule Credo.Check.Warning.ForbiddenModuleTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.ForbiddenModule

  #
  # cases NOT raising issues
  #

  test "it should NOT report with default params" do
    """
    defmodule CredoReplicateIssue do
      alias __MODULE__.Module

      def hello do
        Module.hello()
      end
    end

    defmodule CredoReplicateIssue.Module do
      def hello, do: :world
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report with default params /2" do
    """
    defmodule CredoSampleModule do
      alias CredoSampleModule.ForbiddenModule
      def some_function, do: ForbiddenModule.another_function()
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report on inline fully qualified usage" do
    """
    defmodule CredoSampleModule do
      def some_function, do: CredoSampleModule.ForbiddenModule.another_function()
    end
    """
    |> to_source_file
    |> run_check(@described_check, modules: [CredoSampleModule.ForbiddenModule])
    |> assert_issue(fn issue ->
      assert issue.line_no == 2
      assert issue.column == 26
    end)
  end

  test "it should report on aliases" do
    """
    defmodule CredoSampleModule do
      alias CredoSampleModule.ForbiddenModule
      def some_function, do: ForbiddenModule.another_function()
    end
    """
    |> to_source_file
    |> run_check(@described_check, modules: [CredoSampleModule.ForbiddenModule])
    |> assert_issue(fn issue ->
      assert issue.line_no == 2
      assert issue.column == 9
    end)
  end

  test "it should report on grouped aliases" do
    """
    defmodule CredoSampleModule do
      alias CredoSampleModule.{AllowedModule, ForbiddenModule, ForbiddenModule2}
      def some_function, do: ForbiddenModule.another_function()
    end
    """
    |> to_source_file
    |> run_check(@described_check,
      modules: [CredoSampleModule.ForbiddenModule, CredoSampleModule.ForbiddenModule2]
    )
    |> assert_issues(fn [two, one] ->
      assert one.trigger == "ForbiddenModule"
      assert one.line_no == 2
      assert one.column == 43
      assert two.trigger == "ForbiddenModule2"
      assert two.line_no == 2
      assert two.column == 60
    end)
  end

  test "it should report on import" do
    """
    defmodule CredoSampleModule do
      import CredoSampleModule.ForbiddenModule
      def some_function, do: another_function()
    end
    """
    |> to_source_file
    |> run_check(@described_check, modules: [CredoSampleModule.ForbiddenModule])
    |> assert_issue()
  end

  test "it should report on import only" do
    """
    defmodule CredoSampleModule do
      import CredoSampleModule.ForbiddenModule, only: [another_function: 0]
      def some_function, do: another_function()
    end
    """
    |> to_source_file
    |> run_check(@described_check, modules: [CredoSampleModule.ForbiddenModule])
    |> assert_issue()
  end

  test "it should display a custom message" do
    """
    defmodule CredoSampleModule do
      def some_function, do:
        CredoSampleModule.ForbiddenModule.another_function()
    end
    """
    |> to_source_file
    |> run_check(@described_check, modules: [{CredoSampleModule.ForbiddenModule, "my message"}])
    |> assert_issue(fn issue ->
      assert issue.line_no == 3
      assert issue.column == 5
      assert issue.trigger == "CredoSampleModule.ForbiddenModule"
      assert issue.message == "my message"
    end)
  end

  test "it should work with multiple forbidden modules" do
    """
    defmodule CredoSampleModule do
      def some_function, do: CredoSampleModule.ForbiddenModule.another_function()
      def some_function2, do: CredoSampleModule.ForbiddenModule2.another_function()
    end
    """
    |> to_source_file
    |> run_check(@described_check,
      modules: [CredoSampleModule.ForbiddenModule, CredoSampleModule.ForbiddenModule2]
    )
    |> assert_issues()
  end
end
