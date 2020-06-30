defmodule Credo.SuggestTest do
  use Credo.Test.Case

  @moduletag slow: :integration

  @fixture_example_code "test/fixtures/example_code"

  test "it should NOT report issues on example_code fixture" do
    exec = Credo.CLI.run([@fixture_example_code])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "suggest"
    assert issues == []
  end

  test "it should NOT report issues on example_code fixture (using --strict)" do
    exec = Credo.CLI.run(["--strict", @fixture_example_code])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "suggest"
    assert issues == []
  end

  test "it should NOT report issues using suggest command" do
    exec = Credo.CLI.run(["suggest", @fixture_example_code])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "suggest"
    assert issues == []
  end

  test "it should NOT report issues using suggest command (using --strict)" do
    exec = Credo.CLI.run(["suggest", "--strict", @fixture_example_code])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "suggest"
    assert issues == []
  end
end
