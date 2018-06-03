defmodule Credo.Check.Readability.AliasOrderTest do
  use Credo.TestHelper

  @described_check Credo.Check.Readability.AliasOrder

  #
  # cases NOT raising issues
  #

  test "it should NOT report violation" do
    """
    defmodule Test do
      alias App.Module1
      alias App.Module2
      alias Credo.CLI.Command
      alias Credo.CLI.Filename
      alias Credo.CLI.Sorter
    end
    """
    |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should NOT report violation for independent blocks of alpha-ordered aliases" do
    """
    defmodule Test do
      alias Credo.CLI.Command
      alias Credo.CLI.Filename
      alias Credo.CLI.Sorter

      alias App.Module1
      alias App.Module2
    end
    """
    |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should NOT report violation for multi-aliases when they are alpha-ordered" do
    """
    defmodule Test do
      alias App.CLI.{Filename,Sorter}
      alias App.Foo.{Bar,Baz}

      alias Credo.CLI.Command
      alias Credo.CLI.Filename
      alias Credo.CLI.Sorter

      alias App.Module1
      alias App.Module2
    end
    """
    |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should work with __MODULE__" do
    """
    defmodule Test do
      alias __MODULE__.SubModule

      alias Credo.CLI.Command
      alias Credo.CLI.Filename
      alias Credo.CLI.Sorter
    end
    """
    |> to_source_file
    |> refute_issues(@described_check)
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    """
    defmodule CredoSampleModule do
      alias Credo.CLI.Sorter
      alias Credo.CLI.Command
      alias Credo.CLI.Filename
    end
    """
    |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation with alias groups" do
    """
    defmodule CredoSampleModule do
      alias Credo.CLI.Command
      alias Credo.CLI.Filename
      alias Credo.CLI.Sorter

      alias App.Module2
      alias App.Module1
    end
    """
    |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation with multi-alias" do
    """
    defmodule CredoSampleModule do
      alias App.CLI.{Bar,Baz}
      alias App.Foo.{
        Sorter,
        Command,
        Filename
      }

      alias Credo.CLI.Command
      alias Credo.CLI.Filename
      alias Credo.CLI.Sorter

      alias App.Module1
      alias App.Module2
    end
    """
    |> to_source_file
    |> assert_issue(@described_check)
  end
end
