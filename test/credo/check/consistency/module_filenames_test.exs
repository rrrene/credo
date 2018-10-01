defmodule Credo.Check.Consistency.ModuleFilenamesTest do
  use Credo.TestHelper

  @described_check Credo.Check.Consistency.ModuleFilenames

  test "it should NOT report modules with matching filenames" do
    """
    defmodule CredoFilenameTest do
    end
    """
    |> to_source_file("credo_filename_test.ex")
    |> refute_issues(@described_check)
  end

  test "it should NOT report namespaced modules with matching filenames" do
    """
    defmodule Credo.Checks do
    end
    """
    |> to_source_file("credo/checks.ex")
    |> refute_issues(@described_check)
  end

  test "it should NOT report modules inside a directory with a matching name" do
    """
    defmodule Credo do
    end
    """
    |> to_source_file("lib/credo/credo.ex")
    |> refute_issues(@described_check)
  end

  test "it should report modules with mismatched filenames" do
    """
    defmodule CredoFilenameTest do
    end
    """
    |> to_source_file()
    |> assert_issue(@described_check)
  end
end
