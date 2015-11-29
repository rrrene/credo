defmodule Credo.Check.Readability.ModuleDoc do
  @moduledoc """
  """

  @explanation [check: @moduledoc]

  alias Credo.Code.Module

  use Credo.Check

  def run(%SourceFile{ast: ast} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.traverse(ast, &traverse(&1, &2, issue_meta))
  end

  defp traverse({:defmodule, meta, _arguments} = ast, issues, issue_meta) do
    case Module.attribute(ast, :moduledoc) do
      {:error, _} ->
        mod_name = Module.name(ast)
        {ast, issues ++ [issue_for(meta[:line], mod_name, issue_meta)]}
      _ ->
        {ast, issues}
    end
  end
  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issue_for(line_no, trigger, issue_meta) do
    format_issue issue_meta,
      message: "Modules should have a @moduledoc tag.",
      trigger: trigger,
      line_no: line_no
  end
end
