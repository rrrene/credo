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
    |> assert_issue()
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
    |> assert_issue()
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
      def some_function, do: CredoSampleModule.ForbiddenModule.another_function()
    end
    """
    |> to_source_file
    |> run_check(@described_check, modules: [{CredoSampleModule.ForbiddenModule, "my message"}])
    |> assert_issue(fn issue ->
      expected_message = "my message"

      assert issue.message == expected_message
    end)
  end
end
