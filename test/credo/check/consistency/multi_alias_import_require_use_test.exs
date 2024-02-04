defmodule Credo.Check.Consistency.MultiAliasImportRequireUseTest do
  use Credo.Test.Case

  @described_check Credo.Check.Consistency.MultiAliasImportRequireUse

  @single ~S"""
  defmodule Credo.Sample2 do
    alias Foo.Bar
    alias Foo.Quux
    require Foo.Bar
  end
  """
  @single2 ~S"""
  defmodule Credo.Sample2 do
    import Assertions
    import MyApp.Factory
  end
  """
  @multi ~S"""
  defmodule Credo.Sample3 do
    alias Foo.{Bar, Quux}
    alias Bar.{Baz, Bang}
    alias Foo.Bar
    require Foo.Quux
  end
  """
  @multi_module_same_file ~S"""
  defmodule CredoMultiAliasExample.SetMultiAliasToSingles do
    @moduledoc "This modules does many aliases to set the consistency to multi-alias"

    alias Credo.CLI.{Command, Output}
    alias Config.{Reader, Provider}
  end

  defmodule CredoMultiAliasExample.Foo do
    @moduledoc "This module has a function"

    def test, do: :ok
  end

  defmodule CredoMultiAliasExample.Bar do
    @moduledoc "This module aliases another module"

    alias CredoMultiAliasExample.Foo
  end

  defmodule CredoMultiAliasExample.Baz do
    @moduledoc "This module aliases a different module under the same parent"

    alias CredoMultiAliasExample.Bar
  end
  """

  #
  # cases NOT raising issues
  #

  test "it should NOT report errors when the multi syntax is used consistently" do
    [@multi]
    |> to_source_files
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report errors when there are multiple modules in the same file when the multi syntax is used consistently" do
    [@multi_module_same_file]
    |> to_source_files
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report errors when the single syntax is used consistently" do
    [@single]
    |> to_source_files
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report errors when the single syntax is used consistently /2" do
    [@single, @single2]
    |> to_source_files
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should not report errors when the single syntax is used consistently" do
    [@single]
    |> to_source_files
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report errors when the multi and single syntaxes are mixed" do
    [@single, @multi]
    |> to_source_files
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report errors when the multi and single syntaxes are mixed (two files, one multi-module)" do
    [@single, @multi_module_same_file]
    |> to_source_files
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      # TODO: we need a real trigger for this
      assert issue.trigger == ""
    end)
  end
end
