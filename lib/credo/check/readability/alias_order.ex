defmodule Credo.Check.Readability.AliasOrder do
  use Credo.Check,
    base_priority: :low,
    explanations: [
      check: """
      Alphabetically ordered lists are more easily scannable by the read.

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
      """
    ]

  alias Credo.Code
  alias Credo.Code.Name

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse({:defmodule, _, _} = ast, issues, issue_meta) do
    new_issues =
      ast
      |> extract_alias_groups()
      |> Enum.reduce([], &traverse_groups(&1, &2, issue_meta))

    {ast, issues ++ new_issues}
  end

  defp traverse(ast, issues, _), do: {ast, issues}

  defp traverse_groups(group, acc, issue_meta) do
    group
    |> Enum.chunk_every(2, 1)
    |> Enum.reduce_while(nil, &process_group/2)
    |> case do
      nil ->
        acc

      line ->
        acc ++ [issue_for(issue_meta, line)]
    end
  end

  defp process_group([{line_no, mod_list_second, a}, {_line_no, _mod_list_second, b}], _)
       when a > b do
    module =
      case mod_list_second do
        {base, _} -> base
        value -> value
      end

    issue_opts = issue_opts(line_no, module, module)

    {:halt, issue_opts}
  end

  defp process_group([{line_no1, mod_list_first, _}, {line_no2, mod_list_second, _}], _) do
    issue_opts =
      cond do
        issue = inner_group_order_issue(line_no1, mod_list_first) ->
          issue

        issue = inner_group_order_issue(line_no2, mod_list_second) ->
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

  defp process_group([{line_no1, mod_list_first, _}], _) do
    if issue_opts = inner_group_order_issue(line_no1, mod_list_first) do
      {:halt, issue_opts}
    else
      {:cont, nil}
    end
  end

  defp process_group(_, _), do: {:cont, nil}

  defp inner_group_order_issue(_line_no, {_base, []}), do: nil

  defp inner_group_order_issue(line_no, {base, mod_list}) do
    downcased_mod_list = Enum.map(mod_list, &String.downcase(to_string(&1)))
    sorted_downcased_mod_list = Enum.sort(downcased_mod_list)

    if downcased_mod_list != sorted_downcased_mod_list do
      trigger =
        downcased_mod_list
        |> Enum.with_index()
        |> Enum.find_value(fn {downcased_mod_entry, index} ->
          if downcased_mod_entry != Enum.at(sorted_downcased_mod_list, index) do
            Enum.at(mod_list, index)
          end
        end)

      issue_opts(line_no, [base, trigger], trigger)
    end
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
    |> Code.postwalk(&find_alias_groups/2)
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

  def autocorrect(file) do
    {:ok, quoted} = :"Elixir.Code".string_to_quoted(file)

    modified =
      quoted
      |> Macro.prewalk(&do_autocorrect/1)
      |> Macro.to_string()
      |> :"Elixir.Code".format_string!()
      |> to_string()

    "#{modified}\n"
  end

  defp do_autocorrect({:__block__ = op, meta, [{:alias, _, _} | _] = aliases}) do
    modified =
      aliases
      |> group_aliases()
      |> Enum.map(fn {line, group} ->
        group
        |> Macro.prewalk(&remove_line_numbers/1)
        |> Enum.map(&sort_multi_aliases/1)
        |> sort_aliases()
        |> put_line_number(line)
      end)
      |> List.flatten()

    {op, Keyword.delete(meta, :line), modified}
  end

  defp do_autocorrect(ast), do: ast

  defp put_line_number([{op, meta, args} | tail], line) do
    modified = {op, Keyword.put(meta, :line, line), args}
    [modified | tail]
  end

  defp group_aliases(aliases) do
    chunk_fun = fn
      {_, meta, _} = node, {_, []} ->
        {:cont, {meta[:line], [node]}}

      {_, meta, _} = node, {line, [{_, meta2, _} | _] = chunk} ->
        if meta[:line] - 1 > meta2[:line] do
          {:cont, {line, chunk}, {meta[:line], [node]}}
        else
          {:cont, {line, [node | chunk]}}
        end
    end

    after_fun = fn acc -> {:cont, acc, []} end

    Enum.chunk_while(aliases, {nil, []}, chunk_fun, after_fun)
  end

  defp sort_multi_aliases({op, meta, [{op2, meta2, [{_, _, _} | _] = aliases}]}) do
    {op, meta, [{op2, meta2, sort_aliases(aliases)}]}
  end

  defp sort_multi_aliases(node), do: node

  defp sort_aliases(aliases) do
    Enum.sort_by(aliases, &name_for_sorting/1, fn left, right ->
      Enum.sort([left, right]) == [left, right]
    end)
  end

  defp remove_line_numbers({op, meta, args}) when is_list(meta),
    do: {op, Keyword.delete(meta, :line), args}

  defp remove_line_numbers(ast), do: ast

  defp name_for_sorting({_, _, [{_, _, node}, [as: _]]}), do: compare_name(node)
  defp name_for_sorting({_, _, [{_, _, _} = node]}), do: compare_name(node)
  defp name_for_sorting({_, _, [node]}), do: compare_name(node)
end
