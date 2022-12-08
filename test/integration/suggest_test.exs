defmodule Credo.SuggestTest do
  use Credo.Test.Case

  alias Credo.Test.IntegrationTest

  @moduletag slow: :integration
  @moduletag timeout: 300_000

  @fixture_integration_test_config "test/fixtures/integration_test_config"

  test "it should NOT report issues on --help" do
    exec = IntegrationTest.run(["suggest", "--help"])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "suggest"
    assert issues == []
  end

  test "it should NOT report issues on integration_test_config fixture" do
    exec = IntegrationTest.run([@fixture_integration_test_config])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "suggest"
    assert issues == []
  end

  test "it should NOT report issues on integration_test_config fixture (using --debug)" do
    exec = IntegrationTest.run(["--debug", @fixture_integration_test_config])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "suggest"
    assert issues == []
  end

  test "it should halt on integration_test_config fixture (using --foo)" do
    exec = IntegrationTest.run(["--foo"])

    assert exec.halted == true
  end

  test "it should NOT report issues on integration_test_config fixture (using --strict)" do
    exec = IntegrationTest.run(["--strict", @fixture_integration_test_config])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "suggest"
    assert issues == []
  end

  test "it should NOT report issues using suggest command" do
    exec = IntegrationTest.run(["suggest", @fixture_integration_test_config])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "suggest"
    assert issues == []
  end

  test "it should NOT report issues using suggest command (using --strict)" do
    exec = IntegrationTest.run(["suggest", "--strict", @fixture_integration_test_config])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "suggest"
    assert issues == []
  end

  test "it should report issues using suggest command (using --all)" do
    exec = IntegrationTest.run(["suggest", "--all", @fixture_integration_test_config])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "suggest"
    assert issues == []
  end

  test "it should NOT report issues using suggest command (using --only)" do
    exec = IntegrationTest.run(["suggest", "--only", "module", @fixture_integration_test_config])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "suggest"
    assert issues == []
  end

  test "it should NOT report issues using suggest command (using --ignore)" do
    exec =
      IntegrationTest.run(["suggest", "--ignore", "module", @fixture_integration_test_config])

    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "suggest"
    assert issues == []
  end

  test "it should NOT report issues using suggest command (using --format json)" do
    exec = IntegrationTest.run(["suggest", "--format", "json", @fixture_integration_test_config])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "suggest"
    assert issues == []
  end

  test "it should report issues using suggest command (using --format sarif)" do
    exec =
      IntegrationTest.run([
        "suggest",
        "--config-file",
        "#{@fixture_integration_test_config}/.sarif.exs",
        "--format",
        "sarif"
      ])

    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "suggest"
    assert issues != []

    sarif =
      ExUnit.CaptureIO.capture_io(fn ->
        Credo.CLI.Output.Formatter.SARIF.print_issues(issues, exec)
      end)

    sarif_map = Jason.decode!(sarif)

    assert sarif_map["version"] == "2.1.0"
    assert List.first(sarif_map["runs"])["tool"]["driver"]["name"] == "Credo"

    rules = get_in(sarif_map, ["runs", Access.at(0), "tool", "driver", "rules"])
    results = get_in(sarif_map, ["runs", Access.at(0), "results"])

    assert List.first(rules)["id"] == "EX2004"
    assert List.first(rules)["name"] == "Credo.Check.Design.TagFIXME"

    assert List.first(rules)["helpUri"] ==
             "https://hexdocs.pm/credo/Credo.Check.Design.TagFIXME.html"

    assert length(rules) == 3
    assert length(results) == 5

    first_result = List.first(results)
    assert first_result["level"] == "error"
    assert first_result["rank"] == 23
    assert first_result["ruleId"] == "EX2004"

    second_result = Enum.at(results, 1)
    assert second_result["level"] == nil
    assert second_result["rank"] == 14
    assert second_result["ruleId"] == "EX2005"
  end

  test "it should report issues using suggest command on Credo itself with integration config file" do
    exec =
      IntegrationTest.run([
        "suggest",
        "--config-file",
        "#{@fixture_integration_test_config}/.credo.exs"
      ])

    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "suggest"
    assert issues != []
  end
end
