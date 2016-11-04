defmodule Credo.Check.Warning.NameRedeclarationByDefTest do
  use Credo.TestHelper

  @described_check Credo.Check.Warning.NameRedeclarationByDef

  test "it should NOT report expected code" do
~S"""
defmodule CredoSampleModule do
  use ExUnit.Case

  def foo(~w(a b c)) do
    IO.puts("a b c")
  end

  def fun1 do
    case fun2 do
      x -> x
      %{something: foobar} -> foobar
    end
    [a, b, 42] = fun2
    %{a: a, b: b, c: false} = fun2
    %SomeModule{a: a, b: b, c: false} = fun2

    fun2 + 1
  end

  defp process_map_item({key, value}, acc) when is_atom(key) or is_binary(key) do
    Map.put acc, key, process_exs(value)
  end
  defp process_map_item({key2, value2}, acc) do
    Map.put acc, key, process_exs(value)
  end

  def test(%{one: Type.one}) do
    IO.inspect("hi")
  end

  defmacro fun2 do
    42
  end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should NOT error on valid code" do
~S"""
defmodule CredoSampleModule do
  def to_record(%File.Stat{unquote_splicing(pairs)}) do
    {:file_info, unquote_splicing(vals)}
  end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should report a violation when a parameter has the same name as a predefined function" do
"""
defmodule CredoSampleModule do
  def fun1({a, b, c} = fun2) do
    fun2 + c
  end

  def fun2, do: 42
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation when a parameter has the same name as a predefined function 2" do
"""
defmodule CredoSampleModule do
  def fun1({a, fun2, c}) do
    fun2 + c
  end

  def fun2, do: 42
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

end
