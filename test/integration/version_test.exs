defmodule Credo.VersionTest do
  use Credo.Test.Case

  @moduletag slow: :integration

  test "it should NOT report issues on integration_test_config fixture" do
    exec = Credo.run(["--version"])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "version"
    assert issues == []
  end
end
