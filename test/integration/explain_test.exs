defmodule Credo.ExplainTest do
  use Credo.Test.Case

  @moduletag slow: :integration

  @fixture_example_code_with_location "test/fixtures/example_code/clean_redux.ex:1:11"

  test "it should explain an issue using a filename with location" do
    exec = Credo.run([@fixture_example_code_with_location])
    _issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "explain"
    # TODO: how do we assert this?
    # assert _issues == []
  end

  test "it should explain an issue using explain command" do
    exec = Credo.run(["explain", @fixture_example_code_with_location])
    _issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "explain"
    # TODO: how do we assert this?
    # assert issues == []
  end

  test "it should explain a check using explain command" do
    exec = Credo.run(["explain", @fixture_example_code_with_location])
    _issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "explain"
    # TODO: how do we assert this?
    # assert issues == []
  end
end
