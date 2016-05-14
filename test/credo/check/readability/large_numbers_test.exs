defmodule Credo.Check.Readability.LargeNumbersTest do
  use Credo.TestHelper

  @described_check Credo.Check.Readability.LargeNumbers

  test "it should NOT report expected code" do
"""
def numbers do
  1024 + 1_000_000 + 11_000 + 22_000 + 33_000
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
    |> assert_issues(@described_check)
  end


  test "it should report a violation, since it is formatted incorrectly" do
"""
def numbers do
  1024 + 10_00_00_0 + 43534
end
""" |> to_source_file
    |> assert_issues(@described_check)
  end

  test "it should report only one violation" do
"""
def numbers do
  1024 + 1000000 + 43534
end
""" |> to_source_file
    |> assert_issue(@described_check, only_greater_than: 50000)
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
defp numbers do
  1024 + 43534.0
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation /4" do
"""
defmacro numbers do
  1024 + 1_000000
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end
end
