defmodule Credo.Check.Design.AliasOverusage do
  use Credo.Check,
    base_priority: :normal

  # TODO: Fill out more options...

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    source_file
    |> Credo.Code.prewalk(&traverse(&1, &2, issue_meta))
  end

  defp traverse(
         {:defmodule, _, _} = ast,
         issues,
         issue_meta
       ) do
    mod_deps = Credo.Code.Module.modules(ast)

    module_name_parts =
      Credo.Code.Module.name(ast)
      |> String.split(".")
      |> Enum.map(&String.to_atom/1)

    new_issues =
      Credo.Code.prewalk(
        ast,
        &find_issues(
          &1,
          &2,
          issue_meta,
          module_name_parts,
          mod_deps
        )
      )
      |> Enum.reverse()

    {ast, issues ++ new_issues}
  end

  defp traverse(
         ast,
         issues,
         _issue_meta
       ) do
    {ast, issues}
  end

  # Ignore module attributes
  defp find_issues({:@, _, _}, issues, _, _, _, _, _, _) do
    {nil, issues}
  end

  # Ignore alias containing an `unquote` call
  defp find_issues(
         {:., _, [{:__aliases__, _, mod_list}, :unquote]} = ast,
         issues,
         _,
         _,
         _,
         _,
         _,
         _
       )
       when is_list(mod_list) do
    {ast, issues}
  end

  # Multi-alias
  # i.e. alias Foo.Bar.{Biz, Baz}
  defp find_issues(
         {:alias, _meta1,
          [
            {{:., _meta2, [{:__aliases__, meta, alias_base_parts}, :{}]}, _meta3, alias_suffixes}
          ]} = ast,
         issues,
         issue_meta,
         module_name_parts,
         mod_deps
       ) do
    issues =
      Enum.reduce(alias_suffixes, issues, fn {:__aliases__, meta, suffix_parts}, result ->
        alias_parts = alias_base_parts ++ suffix_parts

        case issue_for(issue_meta, meta, alias_parts, module_name_parts) do
          nil ->
            result

          issue ->
            [issue | result]
        end
      end)
      |> Enum.reject(&is_nil/1)

    {ast, issues}
  end

  defp find_issues(
         {:alias, _meta, [{:__aliases__, meta, alias_parts}]} = ast,
         issues,
         issue_meta,
         module_name_parts,
         mod_deps
       ) do
    case issue_for(issue_meta, meta, alias_parts, module_name_parts) do
      nil ->
        {ast, issues}

      issue ->
        {ast, [issue | issues]}
    end
  end

  defp find_issues(ast, issues, _, module_name_parts, mod_deps) do
    {ast, issues}
  end

  defp issue_for(issue_meta, meta, alias_parts, module_name_parts) do
    common_parts =
      module_name_parts
      |> Enum.zip(alias_parts)
      |> Enum.reduce_while([], fn
        {part, part}, result -> {:cont, [part | result]}
        _, result -> {:halt, result}
      end)
      |> Enum.reverse()

    if length(alias_parts) > length(common_parts) + 1 do
      # trigger = Credo.Code.Name.full(mod_list)

      format_issue(
        issue_meta,
        message: "You are reaching too far into another module: #{Enum.join(alias_parts, ".")}",
        # trigger: trigger,
        line_no: meta[:line_no]
      )
    end
  end
end
