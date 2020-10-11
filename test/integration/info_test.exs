defmodule Credo.InfoTest do
  use Credo.Test.Case

  @moduletag slow: :integration

  test "it should NOT report issues for info" do
    exec = Credo.run(["info"])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "info"
    assert issues == []
  end

  test "it should NOT report issues for info --help" do
    exec = Credo.run(["info", "--help"])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "info"
    assert issues == []
  end

  test "it should NOT report issues for info --verbose" do
    exec = Credo.run(["info", "--verbose"])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "info"
    assert issues == []
  end

  test "it should NOT report issues for info --verbose (using --format json)" do
    exec = Credo.run(["info", "--verbose", "--format", "json"])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "info"
    assert issues == []
  end
end
