defmodule Credo.Check.Readability.FunctionParenthesesTest do
  use Credo.TestHelper

  @described_check Credo.Check.Readability.FunctionParentheses

  test "it should NOT report expected code" do
"""
def fun_name do
end
def fun_name(a, b) do
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end



  test "it should report a violation" do
"""
def fun_name() do
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation /2" do
"""
def fun_name a, b do
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

end
