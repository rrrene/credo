defmodule Credo.Check.Readability.AliasAsTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.AliasAs

  #
  # cases NOT raising issues
  #

  test "it should NOT report violation" do
    ~S'''
    defmodule Test do
      alias App.Module1
      alias App.Module2
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    ~S'''
    defmodule Test do
      alias App.Module1, as: M1
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "as:"
    end)
  end

  test "it should report multiple violations" do
    [issue1, issue2, issue3] =
      ~S'''
      defmodule Test do
        alias App.Module1, as: M1
        alias App.Module2
        alias App.Module3, as: M3
        alias App.Module4, as: M4
      end
      '''
      |> to_source_file
      |> run_check(@described_check)
      |> assert_issues()

    assert issue1.trigger == "as:"
    assert issue2.trigger == "as:"
    assert issue3.trigger == "as:"
  end

  test "it should report on alias __MODULE__, as: Foo" do
    ~S'''
    defmodule Test do
      alias __MODULE__, as: Foo
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end
end
