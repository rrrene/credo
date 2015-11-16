defmodule Credo.Check.Refactor.ABCSizeTest do
  use Credo.TestHelper

  @described_check Credo.Check.Refactor.ABCSize

  def abc_size(source) do
    {:ok, ast} = Credo.Code.ast(source)
    @described_check.abc_size_for(ast)
  end

  def rounded_abc_size(source) do
    source
    |> abc_size
    |> Float.round(2)
  end

  test "it should return the correct ABC size for value assignment" do
    source =
"""
def first_fun do
  x = 1
end
"""
    assert rounded_abc_size(source) == 1.0 # sqrt(1*1 + 0 + 0) = 1
  end

  test "it should return the correct ABC size for assignment to fun call" do
    source =
"""
def first_fun do
  x = call_other_fun
end
"""
    assert rounded_abc_size(source) == 1.41 # sqrt(1*1 + 1*1 + 0) = 1.41
  end

  test "it should return the correct ABC size for assignment to module fun call" do
    source =
"""
def first_fun do
  x = Some.Other.Module.call_other_fun
end
"""
    assert rounded_abc_size(source) == 1.41 # sqrt(1*1 + 1*1 + 0) = 1.41
  end

  test "it should return the correct ABC size /3" do
    source =
"""
def first_fun do
  if some_other_fun, do: call_third_fun
end
"""
    assert rounded_abc_size(source) == 2.24  # sqrt(0 + 2*2 + 1*1) = 2.236
  end

  test "it should return the correct ABC size /4" do
    source =
"""
def first_fun do
  if Some.Other.Module.some_other_fun, do: Some.Other.Module.call_third_fun
end
"""
    assert rounded_abc_size(source) == 2.24  # sqrt(0 + 2*2 + 1*1) = 2.236
  end

  test "it should return the correct ABC size /5" do
    source =
"""
def some_function(foo, bar) do
  if true == true or false == 2 do
    my_options = MyHash.create
  end
  my_options
  |> Enum.each(fn(key, value) ->
    IO.puts key
    IO.puts value
  end)
end
"""
    assert rounded_abc_size(source) == 5.48  # sqrt(1*1 + 5*5 + 2*2) = 5.48
  end






  test "it should NOT report expected code" do
"""
def some_function do
end
""" |> to_source_file
    |> refute_issues(@described_check, max_size: 0)
  end

  test "it should NOT report expected code /2" do
"""
def some_function do
  x = 1
end
""" |> to_source_file
    |> assert_issue(@described_check, max_size: 0)
  end

  test "it should NOT report expected code /x" do
"""
def some_function do
  if 1 == 1 or 2 == 2 do
    my_options = %{}
  end
end
""" |> to_source_file
    |> refute_issues(@described_check, max_size: 3)
  end

  test "it should report a violation" do
"""
def some_function do
  if true == true or false == 2 do
    my_options = MyHash.create
  end
  my_options
  |> Enum.each(fn(key, value) ->
    IO.puts key
    IO.puts value
  end)
end
""" |> to_source_file
    |> assert_issue(@described_check, max_size: 3)
  end

end
