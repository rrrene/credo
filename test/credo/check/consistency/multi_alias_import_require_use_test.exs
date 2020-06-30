defmodule Credo.Check.Consistency.MultiAliasImportRequireUseTest do
  use Credo.Test.Case

  @described_check Credo.Check.Consistency.MultiAliasImportRequireUse

  @single """
  defmodule Credo.Sample2 do
    alias Foo.Bar
    alias Foo.Quux
    require Foo.Bar
  end
  """
  @multi """
  defmodule Credo.Sample3 do
    alias Foo.{Bar, Quux}
    alias Bar.{Baz, Bang}
    alias Foo.Bar
    require Foo.Quux
  end
  """

  #
  # cases NOT raising issues
  #

  test "it should not report errors when the multi syntax is used consistently" do
    [@multi]
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

  test "it should not report errors when the single syntax is used consistently" do
    [@single]
    |> to_source_files
    |> run_check(@described_check)
    |> refute_issues()
  end
end
