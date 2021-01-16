defmodule Credo.ListTest do
  use Credo.Test.Case

  alias Credo.Test.IntegrationTest

  @moduletag slow: :integration
  @moduletag timeout: 300_000

  @fixture_integration_test_config "test/fixtures/integration_test_config"

  test "it should NOT report issues on --help" do
    exec = IntegrationTest.run(["list", "--help"])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "list"
    assert issues == []
  end

  test "it should NOT report issues on integration_test_config fixture (using --debug)" do
    exec = IntegrationTest.run(["list", "--debug", @fixture_integration_test_config])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "list"
    assert issues == []
  end

  test "it should halt on integration_test_config fixture (using --foo)" do
    exec = IntegrationTest.run(["list", "--foo"])

    assert exec.halted == true
  end

  test "it should NOT report issues using list command" do
    exec = IntegrationTest.run(["list", @fixture_integration_test_config])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "list"
    assert issues == []
  end

  test "it should NOT report issues using list command (using --strict)" do
    exec = IntegrationTest.run(["list", "--strict", @fixture_integration_test_config])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "list"
    assert issues == []
  end

  test "it should report issues using list command (using --all)" do
    exec = IntegrationTest.run(["list", "--all", "module", @fixture_integration_test_config])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "list"
    assert issues != []
  end

  test "it should NOT report issues using list command (using --only)" do
    exec = IntegrationTest.run(["list", "--only", "module", @fixture_integration_test_config])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "list"
    assert issues == []
  end

  test "it should NOT report issues using list command (using --ignore)" do
    exec = IntegrationTest.run(["list", "--ignore", "module", @fixture_integration_test_config])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "list"
    assert issues == []
  end

  test "it should NOT report issues using list command (using --format json)" do
    exec = IntegrationTest.run(["list", "--format", "json", @fixture_integration_test_config])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "list"
    assert issues == []
  end

  test "it should report issues using list command on Credo itself with integration config file" do
    exec =
      IntegrationTest.run([
        "list",
        "--config-file",
        "#{@fixture_integration_test_config}/.credo.exs"
      ])

    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "list"
    assert issues != []
  end
end
