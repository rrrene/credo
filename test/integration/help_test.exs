defmodule Credo.HelpTest do
  use Credo.Test.Case

  alias Credo.Test.IntegrationTest

  @moduletag slow: :integration

  test "it should NOT report issues on --help" do
    exec = IntegrationTest.run(["--help"])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "help"
    assert issues == []
  end
end
