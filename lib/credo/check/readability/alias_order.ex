defmodule Credo.Check.Readability.AliasOrder do
  @moduledoc """
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

  @explanation [check: @moduledoc]

  alias Credo.Code
  alias Credo.Code.Name

  use Credo.Check, base_priority: :low

  @doc false
  def run(source_file, params \\ []) do
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
    |> Credo.Backports.Enum.chunk_every(2, 1)
    |> Enum.reduce_while(nil, &process_group/2)
    |> case do
      nil ->
        acc

      line ->
        acc ++ [issue_for(issue_meta, line)]
    end
  end

  defp process_group([{_, mod_list_first, a}, {line_no, mod_list_second, b}], _) when a > b do
    line = [
      line_no: line_no,
      trigger: Name.full(mod_list_second -- mod_list_first),
      module: mod_list_second
    ]

    {:halt, line}
  end

  defp process_group(_, _), do: {:cont, nil}

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
    modules = [{meta[:line], mod_list, mod_list |> Name.full() |> String.downcase()}]

    accumulate_alias_into_group(ast, modules, meta[:line], aliases)
  end

  defp find_alias_groups(
         {:alias, _,
          [
            {{:., _, [{:__aliases__, meta, mod_list}, :{}]}, _, multi_mod_list}
          ]} = ast,
         aliases
       ) do
    modules =
      multi_mod_list
      |> Enum.map(fn {:__aliases__, meta2, mod} ->
        modules = mod_list ++ mod

        {meta2[:line], modules, modules |> Name.full() |> String.downcase()}
      end)
      |> Enum.reverse()

    accumulate_alias_into_group(ast, modules, meta[:line], aliases)
  end

  defp find_alias_groups(ast, aliases), do: {ast, aliases}

  defp accumulate_alias_into_group(ast, modules, line, [{line_no, _, _} | _] = aliases)
       when line_no != 0 and line_no != line - 1 do
    {ast, modules ++ [nil] ++ aliases}
  end

  defp accumulate_alias_into_group(ast, modules, _, aliases) do
    {ast, modules ++ aliases}
  end

  defp issue_for(issue_meta, line_no: line_no, trigger: trigger, module: module) do
    format_issue(
      issue_meta,
      message: "The alias `#{Name.full(module)}` is not alphabetically ordered among its group.",
      trigger: trigger,
      line_no: line_no
    )
  end
end
