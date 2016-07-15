defmodule Credo.Check.Readability.LargeNumbersTest do
  use Credo.TestHelper

  @described_check Credo.Check.Readability.LargeNumbers

  test "it should NOT report expected code" do
    if System.version |> Version.compare("1.3.2") == :lt do
"""
def numbers do
  1024 +
  1_000_000 +
  11_000 +
  22_000 +
  33_000
  10_000..
  20_000
end
"""
    else
"""
def numbers do
  1024 + 1_000_000 + 11_000 + 22_000 + 33_000
  10_000..20_000
end
"""
  end
    |> to_source_file
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

  test "it should report only one violation for ranges /1" do
"""
def numbers do
  10000..20_000
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report only one violation for ranges /2" do
"""
def numbers do
  10_000..20000
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report only two violation for ranges" do
"""
def numbers do
  10000..20000
end
""" |> to_source_file
    |> assert_issues(@described_check)
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

  test "it should format floating point numbers nicely" do
"""
def numbers do
  10000.00001
end
""" |> to_source_file
    |> assert_issue(@described_check, fn(%Credo.Issue{message: message}) ->
      assert Regex.run(~r/[\d\._]+/, message) |> hd ==  "10_000.00001"
    end)
  end

  test "it should report all digits from the source" do
"""
def numbers do
  10000.000010
end
""" |> to_source_file
    |> assert_issue(@described_check, fn(%Credo.Issue{message: message}) ->
      assert Regex.run(~r/[\d\._]+/, message) |> hd ==  "10_000.000010"
    end)
  end

  test "it should not complain about non-decimal numbers" do
"""
def numbers do
  0xFFFF
  0b1111_1111_1111_1111
  0o777_777
end
"""
    |> to_source_file
    |> refute_issues(@described_check)
  end

  test "check old false positive is fixed /1" do
    " defmacro oid_ansi_x9_62, do: quote do: {1,2,840,10_045}"
    |> to_source_file
    |> refute_issues(@described_check)
  end

  test "check old false positive is fixed /2" do
    if System.version |> Version.compare("1.3.2") == :lt do
"""
%{
  bounds: [
    0, 1, 2, 5, 10, 20, 30, 65, 85,
    100, 200, 400, 800,
    1_000,
    2_000,
    4_000,
    8_000,
    16_000]
}
"""
    else
"""
%{
  bounds: [
    0, 1, 2, 5, 10, 20, 30, 65, 85,
    100, 200, 400, 800,
    1_000, 2_000, 4_000, 8_000, 16_000]
}
"""
    end
    |> to_source_file
    |> refute_issues(@described_check)
  end
end
