defmodule Credo.Check.Consistency.ModuleAttributeOrder.Collector do
  use Credo.Check.Consistency.Collector

  alias Credo.Code

  def collect_matches(source_file, _params) do
    source_file
    |> Code.prewalk(&traverse/2, [])
    |> group_usages()
    |> count_occurrences()
  end

  def find_locations_not_matching(expected, source_file) do
    source_file
    |> Code.prewalk(&traverse/2, [])
    |> group_usages()
    |> drop_locations(expected)
  end

  defp attribute_order({:@, _, [{:moduledoc, _, _}]}), do: {0, "moduledoc"}
  defp attribute_order({:@, _, [{:behaviour, _, _}]}), do: {1, "behaviour"}
  defp attribute_order({:use, _, _}), do: {2, "use"}
  defp attribute_order({:import, _, _}), do: {3, "import"}
  defp attribute_order({:alias, _, _}), do: {4, "alias"}
  defp attribute_order({:require, _, _}), do: {5, "require"}
  defp attribute_order({:defstruct, _, _}), do: {6, "defstruct"}
  defp attribute_order({:@, _, [{:type, _, _}]}), do: {7, "@type"}
  defp attribute_order({:@, _, [{:callback, _, _}]}), do: {9, "@callback"}
  defp attribute_order({:@, _, [{:macrocallback, _, _}]}), do: {10, "@macrocallback"}
  defp attribute_order({:@, _, [{:optional_callbacks, _, _}]}), do: {11, "@optional_callbacks"}
  defp attribute_order({:@, _, [{attribute_name, _, _}]}), do: {8, "@#{attribute_name}"}

  defp assert_abc({_, meta, _} = first, second, first_name, second_name, issues) do
    ordering_state =
      if sorted_alphabetically?(first, second) do
        :ordered
      else
        :unordered
      end

    [{ordering_state, first_name, second_name, meta[:line]} | issues]
  end

  defp assert_order([{_, meta, _} = first, second | rest], issues) do
    {first_order, first_name} = attribute_order(first)
    {second_order, second_name} = attribute_order(second)

    new_issues =
      cond do
        first_order > second_order ->
          [{:unordered, first_order, second_order, meta[:line]} | issues]
        first_order == second_order ->
          assert_abc(first, second, first_name, second_name, issues)
        true ->
          [{:ordered, nil, nil, meta[:line]} | issues]
      end

    assert_order([second | rest], new_issues)
  end

  defp assert_order(_, issues) do
    issues
  end

  defp collect_line_no(collection) do
    Enum.map(collection, &Map.get(&1, :line_no))
  end

  defp count_occurrences({ordered, unordered}) do
    %{
      ordered: length(ordered),
      unordered: length(unordered)
    }
  end

  defp drop_locations({_ordered, unordered}, :ordered) do
    collect_line_no(unordered)
  end

  defp drop_locations({ordered, _unordered}, :unordered) do
    collect_line_no(ordered)
  end

  defp group_usages(issues) do
    Enum.split_with(issues, &(elem(&1, 0) == :ordered))
  end

  defp sorted_alphabetically?({_, _, [{_, _, {:::, _, [{first, _, _} | _]}}]}, {_, _, [{_, _, {:::, _, [{second, _, _} | _]}}]}),
    do: first <= second
  defp sorted_alphabetically?({:@, _, [{:behaviour, _, [{_, _, first}]}]}, {:@, _, [{:behaviour, _, [{_, _, second}]}]}),
    do: first <= second
  defp sorted_alphabetically?({:@, _, [{first, _, _}]}, {:@, _, [{second, _, _}]}),
    do: first <= second
  defp sorted_alphabetically?({_, _, [{_, _, first}]}, {_, _, [{_, _, second}]}),
    do: first <= second

  defp traverse({:__block__, _meta, terms} = ast, issues) do
    new_issues = assert_order(terms, issues)
    {ast, new_issues}
  end

  defp traverse(ast, issues) do
    {ast, issues}
  end
end
