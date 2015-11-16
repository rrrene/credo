defmodule Credo.Code.ModuleTest do
  use Credo.TestHelper

  alias Credo.Code.Module

  test "returns the correct parameter counts" do
    {:ok, ast} = """
defmodule Foobar do
end
    """ |> Code.string_to_quoted
    assert 0 == Module.def_count(ast)

    {:ok, ast} = """
defmodule CredoSampleModule do
  def fun1 do
    1
  end
end
    """ |> Code.string_to_quoted
    assert 1 == Module.def_count(ast)

    {:ok, ast} = """
defmodule CredoSampleModule do
  def fun1(nil), do: 1
  def fun1(x), do: fun2 + 1

  defp fun2, do: 42
  defmacro funny_macro, do: quote(true)
end
    """ |> Code.string_to_quoted
    assert 4 == Module.def_count(ast)
  end

  test ".def_names returns the correct function/macro names" do
    {:ok, ast} = """
defmodule Foobar do
end
    """ |> Code.string_to_quoted
    assert [] == Module.def_names(ast)

    {:ok, ast} = """
defmodule CredoSampleModule do
  def fun1 do
    1
  end
end
    """ |> Code.string_to_quoted
    assert [:fun1] == Module.def_names(ast)

    {:ok, ast} = """
defmodule CredoSampleModule do
  def fun1(nil), do: 1
  def fun1(x), do: fun2 + 1

  defp fun2, do: 42
  defmacro funny_macro, do: quote(true)
end
    """ |> Code.string_to_quoted
    assert [:fun1, :fun2, :funny_macro] == Module.def_names(ast)
  end

  test "should return the given module attribute" do
    {:ok, ast} = """
defmodule CredoExample do
  @attr_list [:atom1, :atom2]
  @attr_string "This is a String"
  @attr_number 42

  @moduledoc false
end
""" |> Code.string_to_quoted

    assert [:atom1, :atom2] == Module.attribute(ast, :attr_list)
    assert "This is a String" == Module.attribute(ast, :attr_string)
    assert 42 == Module.attribute(ast, :attr_number)
    assert false == Module.attribute(ast, :moduledoc)
  end



  test "returns the correct names with defining op" do
    {:ok, ast} = """
defmodule CredoSampleModule do
  def fun1(nil), do: 1
  def fun1(x), do: fun2 + 1

  defp fun2, do: 42
  defmacro funny_macro, do: quote(true)
end
    """ |> Code.string_to_quoted
    expected = [{:fun1, :def}, {:fun2, :defp}, {:funny_macro, :defmacro}]
    assert expected == Module.def_names_with_op(ast)
  end

end
