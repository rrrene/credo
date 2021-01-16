defmodule Credo.ExplainTest do
  use Credo.Test.Case

  alias Credo.Test.IntegrationTest

  @moduletag slow: :integration
  @moduletag timeout: 300_000

  @fixture_integration_test_config_with_location "test/credo/code/interpolation_helper_test.exs:167"

  test "it should explain an issue using a filename with location" do
    exec = IntegrationTest.run([@fixture_integration_test_config_with_location])

    assert exec.cli_options.command == "explain"
  end

  test "it should explain an issue using a filename with location (using --format json)" do
    exec =
      IntegrationTest.run([@fixture_integration_test_config_with_location, "--format", "json"])

    assert exec.cli_options.command == "explain"
  end

  test "it should explain an issue using explain command (using --help)" do
    exec = IntegrationTest.run(["explain", "--help"])

    assert exec.cli_options.command == "explain"
  end

  test "it should explain an issue using explain command" do
    exec = IntegrationTest.run(["explain", @fixture_integration_test_config_with_location])

    assert exec.cli_options.command == "explain"
  end

  test "it should explain a check using explain command" do
    exec = IntegrationTest.run(["explain", "Credo.Check.Readability.ModuleDoc"])
    _issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "explain"
  end
end
