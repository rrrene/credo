defmodule Credo.ListTest do
  use Credo.Test.Case

  @moduletag slow: :integration

  @fixture_integration_test_config "test/fixtures/integration_test_config"

  test "it should NOT report issues using list command" do
    exec = Credo.run(["list", @fixture_integration_test_config])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "list"
    assert issues == []
  end

  test "it should NOT report issues using list command (using --strict)" do
    exec = Credo.run(["list", "--strict", @fixture_integration_test_config])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "list"
    assert issues == []
  end
end
