defmodule Credo.Check.Consistency.MultiAliasTest do
  use Credo.TestHelper

  @described_check Credo.Check.Consistency.MultiAlias

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
    require Foo.Quux
    require Foo.Bar
  end
  """

  #
  # cases NOT raising issues
  #

  test "it should not report errors when the multi syntax is used consistently" do
    [@multi]
    |> to_source_files
    |> refute_issues(@described_check)
  end

  #
  # cases raising issues
  #

  test "it should report errors when the multi and single syntaxes are mixed" do
    [@single, @multi]
    |> to_source_files
    |> assert_issue(@described_check)
  end

  test "it should not report errors when the single syntax is used consistently" do
    [@single]
    |> to_source_files
    |> refute_issues(@described_check)
  end
end
