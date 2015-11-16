defmodule Credo.CodeTest do
  use Credo.TestHelper

  test "it should NOT report expected code" do
    lines =
"""
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    some_value = parameter1 + parameter2
  end
end
""" |> Credo.Code.to_lines
    expected = [
      {1, "defmodule CredoSampleModule do"},
      {2, "  def some_function(parameter1, parameter2) do"},
      {3, "    some_value = parameter1 + parameter2"},
      {4, "  end"},
      {5, "end"},
      {6, ""}
    ]
    assert expected == lines
  end

  test "it should parse source" do
    {:ok, ast} = """
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    some_value = parameter1 + parameter2
  end
end
""" |> Credo.Code.ast
    refute is_nil(ast)
  end
end
