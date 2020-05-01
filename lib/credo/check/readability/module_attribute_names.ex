defmodule Credo.Check.Readability.ModuleAttributeNames do
  use Credo.Check,
    base_priority: :high,
    explanations: [
      check: """
      Module attribute names are always written in snake_case in Elixir.

      # snake_case

      @inbox_name "incoming"

      # not snake_case

      @inboxName "incoming"

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """
    ]

  alias Credo.Code.Name

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  # ignore non-alphanumeric @ ASTs, for when you're redefining the @ macro.
  defp traverse({:@, _meta, [{:{}, _, _}]} = ast, issues, _) do
    {ast, issues}
  end

  # TODO: consider for experimental check front-loader (ast)
  # NOTE: see above how we want to exclude certain front-loads
  defp traverse(
         {:@, _meta, [{name, meta, _arguments}]} = ast,
         issues,
         issue_meta
       ) do
    case issue_for_name(issue_meta, name, meta) do
      nil -> {ast, issues}
      val -> {ast, issues ++ [val]}
    end
  end

  defp traverse(ast, issues, _source_file) do
    {ast, issues}
  end

  defp issue_for_name(issue_meta, name, meta)
       when is_binary(name) or is_atom(name) do
    unless name |> to_string |> Name.snake_case?() do
      issue_for(issue_meta, meta[:line], "@#{name}")
    end
  end

  defp issue_for_name(_, _, _), do: nil

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message: "Module attribute names should be written in snake_case.",
      trigger: trigger,
      line_no: line_no
    )
  end
end
