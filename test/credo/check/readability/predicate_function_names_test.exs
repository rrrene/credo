defmodule Credo.Check.Readability.PredicateFunctionNamesTest do
  use Credo.TestHelper

  @described_check Credo.Check.Readability.PredicateFunctionNames

  test "it should NOT report expected code" do
"""
def valid? do
end
defp has_attachment? do
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should report a violation" do
"""
def is_valid? do
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation /2" do
"""
def is_valid do
end
defp is_attachment? do
end
""" |> to_source_file
    |> assert_issues(@described_check)
  end

end
