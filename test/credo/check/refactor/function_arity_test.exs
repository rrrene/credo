defmodule Credo.Check.Refactor.FunctionArityTest do
  use Credo.TestHelper

  @described_check Credo.Check.Refactor.FunctionArity

  test "it should NOT report expected code" do
"""
defmodule Credo.Sample.Module do
  def some_function(p1, p2, p3, p4, p5) when is_nil(p5) do
    some_value = parameter1 + parameter2
  end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should NOT report a violation if defp's are ignored" do
"""
defmodule Credo.Sample.Module do
  defp some_function(p1, p2, p3, p4, p5, p6) do
    some_value = parameter1 + parameter2
  end
end
""" |> to_source_file
    |> refute_issues(@described_check, ignore_defp: true)
  end

  test "it should report a violation" do
"""
defmodule Credo.Sample.Module do
  def some_function(p1, p2, p3, p4, p5, p6) do
    some_value = parameter1 + parameter2
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation for :unless" do
"""
defmodule Credo.Sample.Module do
  def some_function(p1, p2, p3, p4, p5) do
    some_value = parameter1 + parameter2
  end
end
""" |> to_source_file
    |> assert_issue(@described_check, max_arity: 4)
  end
end
