defmodule Credo.InfoTest do
  use Credo.Test.Case

  @moduletag slow: :integration

  test "it should NOT report issues for info" do
    exec = Credo.run(["info"])
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
end
