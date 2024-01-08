defmodule Credo.Check.Readability.AliasAsTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.AliasAs

  #
  # cases NOT raising issues
  #

  test "it should NOT report violation" do
    """
    defmodule Test do
      alias App.Module1
      alias App.Module2
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
    defmodule Test do
      alias App.Module1, as: M1
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "App.Module1"
    end)
  end

  test "it should report multiple violations" do
    [issue1, issue2, issue3] =
      """
      defmodule Test do
        alias App.Module1, as: M1
        alias App.Module2
        alias App.Module3, as: M3
        alias App.Module4, as: M4
      end
      """
      |> to_source_file
      |> run_check(@described_check)
      |> assert_issues()

    assert issue1.trigger == "App.Module1"
    assert issue2.trigger == "App.Module3"
    assert issue3.trigger == "App.Module4"
  end

  test "it should report on alias __MODULE__, as: Foo" do
    """
    defmodule Test do
      alias __MODULE__, as: Foo
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end
end
