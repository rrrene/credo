defmodule Credo.Check.Consistency.ModuleAttributeOrder do
  @moduledoc """
  List module attributes and directives in the following order:

  1.  @moduledoc
  2.  @behaviour
  3.  use
  4.  import
  5.  alias
  6.  require
  7.  defstruct
  8.  @type
  9.  @module_attribute
  10. @callback
  11. @macrocallback
  12. @optional_callbacks

  Like all `Readability` issues, this one is not a technical concern.
  But you can improve the odds of others reading and liking your code by making
  it easier to follow.
  """

  @explanation [check: @moduledoc]

  @attribute_order_message "Module attributes should be ordered correctly"
  @attribute_abc_message "Module attributes should be sorted alphabetically"

  use Credo.Check, base_priority: :low

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
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

  defp assert_abc({_, meta, _} = first, second, first_name, second_name, issues, issue_meta) do
    if sorted_alphabetically?(first, second) do
      issues
    else
      new_issue = issue_for(issue_meta, meta[:line], "#{first_name} occurs after #{second_name}", @attribute_abc_message)
      [new_issue | issues]
    end
  end

  defp assert_order([{_, meta, _} = first, second | rest], issues, issue_meta) do
    {first_order, first_name} = attribute_order(first)
    {second_order, second_name} = attribute_order(second)

    latest_issues =
      cond do
        first_order > second_order ->
          new_issue = issue_for(issue_meta, meta[:line], "#{first_name} occurs before #{second_name}", @attribute_order_message)
          [new_issue | issues]
        first_order == second_order ->
          assert_abc(first, second, first_name, second_name, issues, issue_meta)
        true ->
          issues
      end

    assert_order([second | rest], latest_issues, issue_meta)
  end

  defp assert_order(_, issues, _issue_meta) do
    issues
  end

  defp issue_for(issue_meta, line_no, trigger, message) do
    format_issue(issue_meta, message: message, line_no: line_no, trigger: trigger)
  end

  defp sorted_alphabetically?({_, _, [{_, _, {:::, _, [{first, _, _} | _]}}]}, {_, _, [{_, _, {:::, _, [{second, _, _} | _]}}]}),
    do: first <= second
  defp sorted_alphabetically?({:@, _, [{:behaviour, _, [{_, _, first}]}]}, {:@, _, [{:behaviour, _, [{_, _, second}]}]}),
    do: first <= second
  defp sorted_alphabetically?({:@, _, [{first, _, _}]}, {:@, _, [{second, _, _}]}),
    do: first <= second
  defp sorted_alphabetically?({_, _, [{_, _, first}]}, {_, _, [{_, _, second}]}),
    do: first <= second

  defp traverse({:__block__, _meta, terms} = ast, issues, issue_meta) do
    new_issues = assert_order(terms, issues, issue_meta)
    {ast, new_issues}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end
end
