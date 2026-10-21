defmodule Credo.CLI.Command.Diff.Task.GetGitDiffTest do
  use Credo.Test.Case

  alias Credo.Test.IntegrationTest

  @fixture "test/fixtures/1235-trailing-whitespace"

  test "it should pass switches given before --from-dir on to the previous run" do
    exec =
      IntegrationTest.run([
        "diff",
        "--min-priority",
        "high",
        "--from-dir",
        @fixture,
        "--working-dir",
        @fixture
      ])

    previous_exec = Credo.Execution.get_assign(exec, "credo.diff.previous_exec")

    assert previous_exec.config.min_priority == exec.config.min_priority
  end
end
