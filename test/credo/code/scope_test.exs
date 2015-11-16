defmodule Credo.Code.ScopeTest do
  use Credo.TestHelper

  alias Credo.Code.Scope

  test "it should report the correct scope" do
    {:ok, ast} = """
defmodule Credo.Sample do
  @test_attribute :foo

  def foobar(parameter1, parameter2) do
    String.split(parameter1) + parameter2
  end

  defmodule InlineModule do
    def foobar(v) when is_atom(v) do
      {:ok} = File.read
    end
  end
end

defmodule OtherModule do
  defmacro foo do
    {:ok} = File.read
  end

  defp bar do
    :ok
  end
end
""" |> Code.string_to_quoted

    assert {:defmodule, "Credo.Sample"} == Scope.name(ast, line: 1)
    assert {:defmodule, "Credo.Sample"} == Scope.name(ast, line: 2)
    assert {:defmodule, "Credo.Sample"} == Scope.name(ast, line: 3)
    assert {:def, "Credo.Sample.foobar"} == Scope.name(ast, line: 5)
    assert {:def, "Credo.Sample.InlineModule.foobar"} == Scope.name(ast, line: 10)
    assert {:defmacro, "OtherModule.foo"} == Scope.name(ast, line: 17)
    assert {:defp, "OtherModule.bar"} == Scope.name(ast, line: 21)
  end

  test "it should report the correct scope even outside of modules" do
    {:ok, ast} = """
defmodule Bar do
end

require Foo
IO.puts Foo.message
""" |> Code.string_to_quoted

    assert {:defmodule, "Bar"} == Scope.name(ast, line: 1)
    assert {nil, ""} == Scope.name(ast, line: 5)
  end

  test "it should report the correct scope even outside of modules 2" do
    {:ok, ast} = """
[my_app: [key: :value]]
""" |> Code.string_to_quoted

    assert {nil, ""} == Scope.name(ast, line: 1)
  end

  test "it should report the correct mod_name" do
    assert "Credo.Sample" == Scope.mod_name("Credo.Sample.foobar")
    assert "Credo.Sample" == Scope.mod_name("Credo.Sample")
  end

end
