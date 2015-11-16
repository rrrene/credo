defmodule Credo.Check.Design.AliasUsageTest do
  use Credo.TestHelper

  @described_check Credo.Check.Design.AliasUsage

  test "it should NOT report expected code" do
"""
defmodule CredoSampleModule do
  alias ExUnit.Case

  def fun1 do
    Case.something

    {:error, reason} = __MODULE__.Sup.start_link(fn() -> :foo end)

    [:faint, filename]    # should not throw an error since
    |> IO.ANSI.format     # IO.ANSI is part of stdlib
    |> Credo.Foo.Code.run # Code is part of the stdlib, aliasing it would
                          # override that `Code`, which you probably don't want
  end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should report a violation" do
"""
defmodule CredoSampleModule do
  def fun1 do
    ExUnit.Case.something
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

end
