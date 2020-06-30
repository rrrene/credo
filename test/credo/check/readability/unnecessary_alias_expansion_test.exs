defmodule Credo.Check.Readability.UnnecessaryAliasExpansionTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.UnnecessaryAliasExpansion

  #
  # cases NOT raising issues
  #

  test "it should NOT report violation" do
    """
    defmodule Test do
      alias App.Module1
      alias App.{Module2, Module3}
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    """
    defmodule CredoSampleModule do
      alias App.Module1
      alias App.Module2.{Module3}
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation for double expansion" do
    """
    defmodule CredoSampleModule do
      alias App.Module1
      alias App.{Module2}.{Module3}
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end
end
