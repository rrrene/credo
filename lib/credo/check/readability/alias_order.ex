defmodule Credo.Check.Readability.AliasOrder do
  use Credo.Check,
    id: "EX3002",
    base_priority: :low,
    param_defaults: [
      sort_method: :alpha
    ],
    explanations: [
      check: """
      Alphabetically ordered lists are more easily scannable by the reader.

          # preferred

          alias ModuleA
          alias ModuleB
          alias ModuleC

          # NOT preferred

          alias ModuleA
          alias ModuleC
          alias ModuleB

      Alias should be alphabetically ordered among their group:

          # preferred

          alias ModuleC
          alias ModuleD

          alias ModuleA
          alias ModuleB

          # NOT preferred

          alias ModuleC
          alias ModuleD

          alias ModuleB
          alias ModuleA

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """,
      params: [
        sort_method: """
        The ordering method to use.

        Options
        - `:alpha` - Alphabetical case-insensitive sorting.
        - `:ascii` - Case-sensitive sorting where upper case characters are ordered
                      before their lower case equivalent.
        """
      ]
    ]

  alias Credo.Code.Name

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    sort_method = Params.get(params, :sort_method, __MODULE__)
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta, sort_method))
  end

  defp traverse({:defmodule, _, _} = ast, issues, issue_meta, sort_method) do
    new_issues =
      ast
      |> extract_alias_groups()
      |> Enum.reduce([], &traverse_groups(&1, &2, issue_meta, sort_method))

    {ast, issues ++ new_issues}
  end

  defp traverse(ast, issues, _, _), do: {ast, issues}

  defp traverse_groups(group, acc, issue_meta, sort_method) do
    group
    |> Enum.chunk_every(2, 1)
    |> Enum.reduce_while(nil, fn chunk, _ -> process_group(sort_method, chunk) end)
    |> case do
      nil ->
        acc

      line ->
        acc ++ [issue_for(issue_meta, line)]
    end
  end

  defp process_group(:alpha, [
         {line_no, mod_list_second, a},
         {_line_no, _mod_list_second, b}
       ])
       when a > b do
    module =
      case mod_list_second do
        {base, _} -> base
        value -> value
      end

    issue_opts = issue_opts(line_no, module, module)

    {:halt, issue_opts}
  end

  defp process_group(:ascii, [
         {line_no, {a, []}, _},
         {_line_no, {b, []}, _}
       ])
       when a > b do
    {:halt, issue_opts(line_no, a, a)}
  end

  defp process_group(sort_method, [{line_no1, mod_list_first, _}, {line_no2, mod_list_second, _}]) do
    issue_opts =
      cond do
        issue = inner_group_order_issue(sort_method, line_no1, mod_list_first) ->
          issue

        issue = inner_group_order_issue(sort_method, line_no2, mod_list_second) ->
          issue

        true ->
          nil
      end

    if issue_opts do
      {:halt, issue_opts}
    else
      {:cont, nil}
    end
  end

  defp process_group(sort_method, [{line_no1, mod_list_first, _}]) do
    if issue_opts = inner_group_order_issue(sort_method, line_no1, mod_list_first) do
      {:halt, issue_opts}
    else
      {:cont, nil}
    end
  end

  defp process_group(_, _), do: {:cont, nil}

  defp inner_group_order_issue(_sort_method, _line_no, {_base, []}), do: nil

  defp inner_group_order_issue(:ascii = _sort_method, line_no, {base, mod_list}) do
    sorted_mod_list = Enum.sort(mod_list)

    if mod_list != sorted_mod_list do
      issue_opts(line_no, base, mod_list, mod_list, sorted_mod_list)
    end
  end

  defp inner_group_order_issue(_sort_method, line_no, {base, mod_list}) do
    downcased_mod_list = Enum.map(mod_list, &String.downcase(to_string(&1)))
    sorted_downcased_mod_list = Enum.sort(downcased_mod_list)

    if downcased_mod_list != sorted_downcased_mod_list do
      issue_opts(line_no, base, mod_list, downcased_mod_list, sorted_downcased_mod_list)
    end
  end

  defp issue_opts(line_no, base, mod_list, comparison_mod_list, sorted_comparison_mod_list) do
    trigger =
      comparison_mod_list
      |> Enum.with_index()
      |> Enum.find_value(fn {comparison_mod_entry, index} ->
        if comparison_mod_entry != Enum.at(sorted_comparison_mod_list, index) do
          Enum.at(mod_list, index)
        end
      end)

    issue_opts(line_no, [base, trigger], trigger)
  end

  defp issue_opts(line_no, module, trigger) do
    %{
      line_no: line_no,
      trigger: trigger,
      module: module
    }
  end

  defp extract_alias_groups({:defmodule, _, _} = ast) do
    ast
    |> Credo.Code.postwalk(&find_alias_groups/2)
    |> Enum.reverse()
    |> Enum.reduce([[]], fn definition, acc ->
      case definition do
        nil ->
          [[]] ++ acc

        definition ->
          [group | groups] = acc
          [group ++ [definition]] ++ groups
      end
    end)
    |> Enum.reverse()
  end

  defp find_alias_groups(
         {:alias, _, [{:__aliases__, meta, mod_list} | _]} = ast,
         aliases
       ) do
    compare_name = compare_name(ast)
    modules = [{meta[:line], {Name.full(mod_list), []}, compare_name}]

    accumulate_alias_into_group(ast, modules, meta[:line], aliases)
  end

  defp find_alias_groups(
         {:alias, _,
          [
            {{:., _, [{:__aliases__, meta, mod_list}, :{}]}, _, multi_mod_list}
          ]} = ast,
         aliases
       ) do
    multi_mod_list =
      multi_mod_list
      |> Enum.map(fn {:__aliases__, _, mod_list} -> mod_name(mod_list) end)

    compare_name = compare_name(ast)
    modules = [{meta[:line], {Name.full(mod_list), multi_mod_list}, compare_name}]

    nested_mod_line = meta[:line] + 1
    accumulate_alias_into_group(ast, modules, nested_mod_line, aliases)
  end

  defp find_alias_groups(ast, aliases), do: {ast, aliases}

  defp mod_name(mod_list) do
    Enum.map_join(mod_list, ".", &to_string/1)
  end

  defp compare_name(value) do
    value
    |> Macro.to_string()
    |> String.downcase()
    |> String.replace(~r/[\{\}]/, "")
    |> String.replace(~r/,.+/, "")
  end

  defp accumulate_alias_into_group(ast, modules, line, [{line_no, _, _} | _] = aliases)
       when line_no != 0 and line_no != line - 1 do
    {ast, modules ++ [nil] ++ aliases}
  end

  defp accumulate_alias_into_group(ast, modules, _, aliases) do
    {ast, modules ++ aliases}
  end

  defp issue_for(issue_meta, %{line_no: line_no, trigger: trigger, module: module}) do
    format_issue(
      issue_meta,
      message: "The alias `#{Name.full(module)}` is not alphabetically ordered among its group.",
      trigger: trigger,
      line_no: line_no
    )
  end
end
