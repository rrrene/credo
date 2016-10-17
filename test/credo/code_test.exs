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

  test "it issues a parser error when reading non-utf8 files" do
    # This is `"René"` encoded as ISO-8859-1, which causes a `UnicodeConversionError`.
    source_file = <<34, 82, 101, 110, 233, 34>>
    {:error, [error]} = Credo.Code.ast(source_file)
    %Credo.Issue{message: message, line_no: 1} = error

    assert "invalid encoding starting at <<233, 34>>" == message
  end
end
