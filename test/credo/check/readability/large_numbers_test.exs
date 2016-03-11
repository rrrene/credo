defmodule Credo.Check.Readability.LargeNumbersTest do
  use Credo.TestHelper

  @described_check Credo.Check.Readability.LargeNumbers

  @moduletag :to_be_implemented

  test "it should NOT report expected code" do
"""
def numbers do
  1024 + 1_000_000 + 43_534
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end



  test "it should report a violation" do
"""
def numbers do
  1024 + 1000000 + 43534
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation /2" do
"""
defp numbers do
  1024 + 43534
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation /3" do
"""
defmacro numbers do
  1024 + 1_000000
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end
end
