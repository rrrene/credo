defmodule Credo.Check.Readability.ModuleDocTest do
  use Credo.TestHelper

  @described_check Credo.Check.Readability.ModuleDoc

  test "it should NOT report expected code" do
"""
defmodule CredoSampleModule do
  @moduledoc "Something"
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should not report exception modules" do
"""
defmodule CredoSampleModule do
  defexception message: "Bad luck"
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should report a violation" do
"""
defmodule CredoSampleModule do
  def some_fun do
    x = 1; y = 2
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

end
