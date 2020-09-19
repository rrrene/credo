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

  defp process_group([{_, _mod_list_first, a}, {line_no, mod_list_second, b}], _)
       when a > b do
    issue_opts = issue_opts(line_no, mod_list_second)

    {:halt, issue_opts}
  end

  defp process_group([{line_no1, mod_list_first, _}, {line_no2, mod_list_second, _}], _) do
    issue_opts =
      cond do
        inner_group_order_issue(mod_list_first) ->
          issue_opts(line_no1, mod_list_first)

        inner_group_order_issue(mod_list_second) ->
          issue_opts(line_no2, mod_list_second)

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
    issue_opts =
      if inner_group_order_issue(mod_list_first) do
        issue_opts(line_no1, mod_list_first)
      else
        nil
      end

    if issue_opts do
      {:halt, issue_opts}
    else
      {:cont, nil}
    end
  end

  defp process_group(_, _), do: {:cont, nil}

  defp inner_group_order_issue({_base, []}), do: nil

  defp inner_group_order_issue({_base, mod_list}) do
    mod_list = Enum.map(mod_list, &String.downcase(to_string(&1)))

    mod_list != Enum.sort(mod_list)
  end

  defp issue_opts(line_no, mod_list) do
    {base, _} = mod_list

    %{
      line_no: line_no,
      trigger: base,
      module: base
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
    mod_list
    |> Enum.map(&to_string/1)
    |> Enum.join(".")
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
