defmodule Credo.SuggestTest do
  use Credo.Test.Case

  @moduletag slow: :integration
  @moduletag timeout: 300_000

  @fixture_integration_test_config "test/fixtures/integration_test_config"

  test "it should NOT report issues on --help" do
    exec = Credo.run(["suggest", "--help"])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "suggest"
    assert issues == []
  end

  test "it should NOT report issues on integration_test_config fixture" do
    exec = Credo.run([@fixture_integration_test_config])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "suggest"
    assert issues == []
  end

  test "it should NOT report issues on integration_test_config fixture (using --debug)" do
    exec = Credo.run(["--debug", @fixture_integration_test_config])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "suggest"
    assert issues == []
  end

  test "it should halt on integration_test_config fixture (using --foo)" do
    exec = Credo.run(["--foo"])

    assert exec.halted == true
  end

  test "it should NOT report issues on integration_test_config fixture (using --strict)" do
    exec = Credo.run(["--strict", @fixture_integration_test_config])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "suggest"
    assert issues == []
  end

  test "it should NOT report issues using suggest command" do
    exec = Credo.run(["suggest", @fixture_integration_test_config])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "suggest"
    assert issues == []
  end

  test "it should NOT report issues using suggest command (using --strict)" do
    exec = Credo.run(["suggest", "--strict", @fixture_integration_test_config])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "suggest"
    assert issues == []
  end

  test "it should report issues using suggest command (using --all)" do
    exec = Credo.run(["suggest", "--all", "module", @fixture_integration_test_config])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "suggest"
    assert issues != []
  end

  test "it should NOT report issues using suggest command (using --only)" do
    exec = Credo.run(["suggest", "--only", "module", @fixture_integration_test_config])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "suggest"
    assert issues == []
  end

  test "it should NOT report issues using suggest command (using --ignore)" do
    exec = Credo.run(["suggest", "--ignore", "module", @fixture_integration_test_config])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "suggest"
    assert issues == []
  end

  test "it should NOT report issues using suggest command (using --format json)" do
    exec = Credo.run(["suggest", "--format", "json", @fixture_integration_test_config])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "suggest"
    assert issues == []
  end

  test "it should report issues using suggest command on Credo itself with integration config file" do
    exec =
      Credo.run([
        "suggest",
        "--config-file",
        "#{@fixture_integration_test_config}/.credo.exs"
      ])

    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "suggest"
    assert issues != []
  end
end
