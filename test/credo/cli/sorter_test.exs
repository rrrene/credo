defmodule Credo.CLI.SorterTest do
  use Credo.Test.Case

  alias Credo.CLI.Sorter

  test "it should work" do
    starting_order = [:a, :b]
    list = [1, 2, :a, 3, 4, :b, 5, 6]
    expected = [:a, :b, 1, 2, 3, 4, 5, 6]
    assert expected == list |> Sorter.to_start(starting_order)
  end

  test "it should work when items in starting_order are missing in list" do
    starting_order = [:a, :b, :i_dont_exists]
    list = [1, 2, :a, 3, 4, :b, 5, 6]
    expected = [:a, :b, 1, 2, 3, 4, 5, 6]
    assert expected == list |> Sorter.to_start(starting_order)
  end

  test "it should work with ending_order" do
    ending_order = [3, 2, 1]
    list = [1, 2, :a, 3, 4, :b, 5, 6]
    expected = [:a, 4, :b, 5, 6, 3, 2, 1]
    assert expected == list |> Sorter.to_end(ending_order)
  end

  test "it should work when items in ending_order are missing in list" do
    ending_order = [3, 2, 1, :i_dont_exists]
    list = [1, 2, :a, 3, 4, :b, 5, 6]
    expected = [:a, 4, :b, 5, 6, 3, 2, 1]
    assert expected == list |> Sorter.to_end(ending_order)
  end

  test "it should work with start and end" do
    starting_order = [:a, :b, :i_dont_exists]
    ending_order = [3, 2, 1]
    list = [1, 2, :a, 3, 4, :b, 5, 6]
    expected = [:a, :b, 4, 5, 6, 3, 2, 1]
    assert expected == list |> Sorter.ensure(starting_order, ending_order)
  end
end
