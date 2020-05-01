defmodule Credo.ListTest do
  use Credo.Test.Case

  @moduletag slow: :integration

  @fixture_example_code "test/fixtures/example_code"

  test "it should NOT report issues using list command" do
    exec = Credo.CLI.run(["list", @fixture_example_code])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "list"
    assert issues == []
  end

  test "it should NOT report issues using list command (using --strict)" do
    exec = Credo.CLI.run(["list", "--strict", @fixture_example_code])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "list"
    assert issues == []
  end
end
