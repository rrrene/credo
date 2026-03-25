defmodule Credo.Check.Design.MissingCheckInConfigTest do
  use Credo.Test.Case

  alias Credo.Execution

  @described_check Credo.Check.Design.MissingCheckInConfig

  #
  # cases NOT raising issues
  #

  test "it should NOT report correct behaviour" do
    []
    |> to_source_files
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report with param :compare_to given as :credo_checks" do
    []
    |> to_source_files
    |> run_check(@described_check, compare_to: :credo_checks)
    |> refute_issues()
  end

  test "it should NOT report with param :compare_to given as :credo_checks_enabled_by_default" do
    []
    |> to_source_files
    |> run_check(@described_check, compare_to: :credo_checks_enabled_by_default)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    source_file = to_source_file("", Credo.Check.Design.MissingCheckInConfig.source_file_stub().filename)

    config = %{
      checks: %{
        enabled: [{Credo.Check.Foo.NonExistentCheck, []}, {Credo.Check.Bar.NonCheck2, []}],
        disabled: []
      }
    }

    exec = Execution.put_assign(Execution.build(), "credo.validated_config", config)

    [source_file]
    |> run_check(@described_check, [], exec)
    |> assert_issues()
  end
end
