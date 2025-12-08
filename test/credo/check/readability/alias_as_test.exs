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
    |> assert_issue(%{trigger: "as:"})
  end

  test "it should report multiple violations" do
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
    |> assert_issues(3)
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

  test "it should ignore violations for ignored modules" do
    """
    defmodule Test do
      alias App.Module1, as: M1
    end
    """
    |> to_source_file
    |> run_check(@described_check, ignore: [App.Module1])
    |> refute_issues()
  end

  test "it should ignore violations for ignored modules (using binaries)" do
    """
    defmodule Test do
      alias App.Module1, as: M1
    end
    """
    |> to_source_file
    |> run_check(@described_check, ignore: ["App.Module1"])
    |> refute_issues()
  end

  test "it should ignore violations for __MODULE__ when :__MODULE__ is in ignore list" do
    """
    defmodule Test do
      alias __MODULE__, as: Foo
    end
    """
    |> to_source_file
    |> run_check(@described_check, ignore: [:__MODULE__])
    |> refute_issues()
  end

  test "it should not raise on alias __MODULE__, as: Foo" do
    _ =
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
