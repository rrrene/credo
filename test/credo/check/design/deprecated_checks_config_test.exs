defmodule Credo.Check.Design.DeprecatedChecksConfigTest do
  use Credo.Test.Case

  alias Credo.Execution

  @described_check Credo.Check.Design.DeprecatedChecksConfig

  #
  # cases NOT raising issues
  #

  test "it should NOT report correct behaviour" do
    []
    |> to_source_files
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation for giving a list instead of a map for :checks" do
    source_file = to_source_file("", Credo.Check.Design.MissingCheckInConfig.source_file_stub().filename)

    config = %{
      checks: [{Credo.Check.Foo.BarCheck, []}, {Credo.Check.Bar.BazCheck, []}]
    }

    exec = Execution.put_assign(Execution.build(), "credo.validated_config", config)

    [source_file]
    |> run_check(@described_check, [], exec)
    |> assert_issue(%{trigger: Credo.Issue.no_trigger(), message: ~r/:checks/})
  end

  test "it should report a violation for deactivating checks by setting params to `false`" do
    source_file = to_source_file("", Credo.Check.Design.MissingCheckInConfig.source_file_stub().filename)

    config = %{
      checks: %{
        enabled: [{Credo.Check.Foo.BarCheck, false}, {Credo.Check.Bar.BazCheck, []}]
      }
    }

    exec = Execution.put_assign(Execution.build(), "credo.validated_config", config)

    [source_file]
    |> run_check(@described_check, [], exec)
    |> assert_issue(%{trigger: Credo.Issue.no_trigger(), message: ~r/false/})
  end
end
