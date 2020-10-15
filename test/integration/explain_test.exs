defmodule Credo.ExplainTest do
  use Credo.Test.Case

  @moduletag slow: :integration
  @moduletag timeout: 300_000

  @fixture_integration_test_config_with_location "test/fixtures/integration_test_config/clean_redux.ex:1:11"

  test "it should explain an issue using a filename with location" do
    exec = Credo.run([@fixture_integration_test_config_with_location])

    assert exec.cli_options.command == "explain"
  end

  test "it should explain an issue using a filename with location (using --format json)" do
    exec = Credo.run([@fixture_integration_test_config_with_location, "--format", "json"])

    assert exec.cli_options.command == "explain"
  end

  test "it should explain an issue using explain command (using --help)" do
    exec = Credo.run(["explain", "--help"])

    assert exec.cli_options.command == "explain"
  end

  test "it should explain an issue using explain command" do
    exec = Credo.run(["explain", @fixture_integration_test_config_with_location])

    assert exec.cli_options.command == "explain"
  end

  test "it should explain a check using explain command" do
    exec = Credo.run(["explain", "Credo.Check.Readability.ModuleDoc"])
    _issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "explain"
  end
end
