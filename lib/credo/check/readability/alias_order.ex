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

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__, %{alias_memo: [], alias_groups: []})

    Credo.Code.prewalk(source_file, &walk/2, ctx)
    |> extract_group_from_memo()
    |> find_issues()
  end

  defp walk(
         {:alias, _, [{:__aliases__, meta, mod_list} | _]},
         %{params: %{sort_method: sort_method}} = ctx
       ) do
    fullname = Credo.Code.Name.full(mod_list)
    line = meta[:line]

    candidate =
      {{compare_name(fullname, sort_method), line, line},
       module: fullname, trigger: fullname, column: meta[:column]}

    {nil, extract_group_and_add_candidate(ctx, candidate, line)}
  end

  defp walk(
         {:alias, _, [{{:., _, [{:__aliases__, _, base_mod_list}, :{}]}, meta, multi_mod_list}]},
         %{params: %{sort_method: sort_method}} = ctx
       ) do
    candidates = multi_candidates(base_mod_list, multi_mod_list, sort_method)
    line = meta[:line]
    {{compare, _, _}, _} = List.first(candidates)

    candidate =
      {{compare, line, meta[:closing][:line]}, [multi_aliases: candidates]}

    {nil, extract_group_and_add_candidate(ctx, candidate, line)}
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp multi_candidates(base_mod_list, multi_mod_list, sort_method) do
    Enum.map(multi_mod_list, fn {:__aliases__, meta, mod_list} ->
      fullname = Credo.Code.Name.full(base_mod_list ++ mod_list)
      trigger = Credo.Code.Name.full(mod_list)

      {{compare_name(fullname, sort_method), meta[:line], meta[:line]},
       module: fullname, trigger: trigger, column: meta[:column]}
    end)
  end

  defp extract_group_and_add_candidate(ctx, candidate, line) do
    ctx =
      if new_group?(ctx, line) do
        extract_group_from_memo(ctx)
      else
        ctx
      end

    unshift(ctx, :alias_memo, candidate)
  end

  defp extract_group_from_memo(ctx) do
    ctx
    |> unshift(:alias_groups, ctx.alias_memo)
    |> Map.put(:alias_memo, [])
  end

  defp new_group?(%{alias_memo: []}, _line), do: true

  defp new_group?(%{alias_memo: [{{_, _, line_end}, _} | _]}, line) do
    line != line_end + 1
  end

  defp compare_name(value, :alpha) do
    value
    |> String.downcase()
    |> compare_name(nil)
  end

  defp compare_name(value, _sort_method) do
    value
    |> String.replace(~r/[\{\}]/, "")
    |> String.replace(~r/,.+/, "")
  end

  defp find_issues(ctx) do
    Enum.flat_map(ctx.alias_groups, fn group ->
      group = Enum.reverse(group)

      find_multi_alias_issues(ctx, group) ++ List.wrap(find_issue(ctx, group))
    end)
  end

  defp find_multi_alias_issues(ctx, group) do
    Enum.map(group, fn {_pos_tuple, meta} ->
      if meta[:multi_aliases] do
        find_issue(ctx, meta[:multi_aliases])
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp find_issue(ctx, group) do
    sorted = Enum.sort(group)

    if group != sorted do
      {first_mismatch, _} =
        Enum.zip(group, sorted)
        |> Enum.find(fn {a, b} -> a != b end)

      {{_, line_no, _}, meta} = first_mismatch

      issue_for(ctx, line_no, meta[:column], meta[:trigger], meta[:module])
    end
  end

  defp issue_for(ctx, line_no, column, trigger, module) do
    format_issue(
      ctx,
      message: "The alias `#{module}` is not alphabetically ordered among its group.",
      trigger: trigger,
      line_no: line_no,
      column: column
    )
  end
end
