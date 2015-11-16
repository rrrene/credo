defmodule Credo.Check.Refactor.CyclomaticComplexityTest do
  use Credo.TestHelper

  @described_check Credo.Check.Refactor.CyclomaticComplexity

  def complexity(source) do
    {:ok, ast} = Credo.Code.ast(source)
    @described_check.complexity_for(ast)
  end

  def rounded_complexity(source) do
    source
    |> complexity
  end

  test "it should return the complexity for a function without branches" do
    source =
"""
def first_fun do
  x = 1
end
"""
    assert 1 == rounded_complexity(source) # 1 for fun def
  end

  test "it should return the complexity for a function with a single branch" do
    source =
"""
def first_fun do
  if some_other_fun, do: call_third_fun
end
"""
    assert 2 == rounded_complexity(source)# 1 for fun def, 1 for :if
  end

  test "it should return the complexity for a function with a single branch /2" do
    source =
"""
def first_fun do
  if 1 == 1 or 2 == 2 do
    my_options = %{}
  end
end
"""
    assert 3 == rounded_complexity(source) # 1 for fun def, 1 for :if, 1 for :or
  end

  test "it should return the complexity for a function with multiple branches" do
    source =
"""
def first_fun(param) do
  case param do
    1 -> do_something
    2 -> do_something_else
    _ -> do_something_even_more_else
  end
end
"""
    assert 4 == rounded_complexity(source) # 1 for fun def, *0* for :case, 1 for each ->
  end

  test "it should return the complexity for a function with multiple branches containing other branches" do
    source =
"""
def first_fun(param) do
  case param do
    1 ->
      if 1 == 1 or 2 == 2 do
        my_options = %{}
      end
    2 -> do_something_else
    _ -> do_something_even_more_else
  end
end
"""
    assert 6 == rounded_complexity(source) # 1 for fun def, *0* for :case, 1 for each ->, 2 for the :if inside the first ->
  end

  test "it should return the complexity for a function with multiple branches containing other branches /2" do
    source =
"""
def first_fun do
  if first_condition do
    if second_condition && third_condition, do: call_something
    if fourth_condition || fifth_condition, do: call_something_else
  end
end
"""
    assert 6 == rounded_complexity(source)
  end

  test "it should return the complexity for a function with multiple branches containing other branches /3" do
    source =
"""
def first_fun do
  if first_condition do
    call_something
  else
    if second_condition do
      call_something
    else
      if third_condition, do: call_something
    end
    if fourth_condition, do: call_something_else
  end
end
"""
    assert 5 == rounded_complexity(source)
  end




  test "it should NOT report expected code" do
"""
def some_function do
  x = 1
end
""" |> to_source_file
    |> refute_issues(@described_check, max_complexity: 1)
  end

  test "it should NOT report expected code /2" do
"""
def some_function do
  if x == 0, do: x = 1
end
""" |> to_source_file
    |> assert_issue(@described_check, max_complexity: 1)
  end

  test "it should NOT report expected code /x" do
"""
def some_function do
  if 1 == 1 or 2 == 2 do
    my_options = %{}
  end
end
""" |> to_source_file
    |> refute_issues(@described_check, max_complexity: 3)
  end

  test "it should report a violation" do
"""
def first_fun do
  if first_condition do
    call_something
  else
    if second_condition do
      call_something
    else
      if third_condition, do: call_something
    end
    if fourth_condition, do: call_something_else
  end
end
""" |> to_source_file
    |> assert_issue(@described_check, max_complexity: 4)
  end

  test "it should report a violation on def rather than when" do
  """
defmodule CredoTest do
  defp foobar(v) when is_atom(v) do
    if first_condition do
      if second_condition && third_condition, do: call_something
      if fourth_condition || fifth_condition, do: call_something_else
    end
  end
end
  """ |> to_source_file
      |> assert_issue(@described_check, max_complexity: 4)
      |> assert_trigger(:foobar)

  end


end
