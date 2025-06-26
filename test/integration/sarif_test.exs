defmodule Credo.SarifTest do
  use Credo.Test.Case

  alias Credo.Test.IntegrationTest

  @moduletag timeout: 300_000

  test "it should report issues using suggest command (using --format sarif)" do
    exec =
      IntegrationTest.run(
        ~w[suggest --config-file test/fixtures/integration_test_config/.sarif.exs --format sarif]
      )

    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "suggest"
    assert issues != []

    sarif =
      ExUnit.CaptureIO.capture_io(fn ->
        Credo.CLI.Output.Formatter.SARIF.print_issues(issues, exec)
      end)

    sarif_map = Jason.decode!(sarif)

    assert sarif_map["version"] == "2.1.0"

    first_run = List.first(sarif_map["runs"])

    assert first_run["tool"]["driver"]["name"] == "Credo"

    rules = first_run["tool"]["driver"]["rules"]
    results = first_run["results"]

    assert rules != []
    assert results != []
  end
end
