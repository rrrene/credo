defmodule Credo.Check.Readability.ModuleNames do
  @moduledoc """
  Module names are always written in PascalCase in Elixir.

      # PascalCase

      defmodule MyApp.WebSearchController do
        # ...
      end

      # not PascalCase

      defmodule MyApp.Web_searchController do
        # ...
      end

  Like all `Readability` issues, this one is not a technical concern.
  But you can improve the odds of other reading and liking your code by making
  it easier to follow.
  """

  @explanation [check: @moduledoc]

  alias Credo.Code.Name

  use Credo.Check, base_priority: :high

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse({:defmodule, _meta, arguments} = ast, issues, issue_meta) do
    {ast, issues_for_def(arguments, issues, issue_meta)}
  end
  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issues_for_def(body, issues, issue_meta) do
    case Enum.at(body, 0) do
      {:__aliases__, meta, names} ->
        names |> Enum.join(".") |> issues_for_name(meta, issues, issue_meta)
      _ ->
        issues
    end
  end

  def issues_for_name(name, meta, issues, issue_meta) do
    if name |> to_string |> String.split(".") |> Enum.all?(&Name.pascal_case?/1) do
      issues
    else
      [issue_for(issue_meta, meta[:line], name) | issues]
    end
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue issue_meta,
      message: "Module names should be written in PascalCase.",
      trigger: trigger,
      line_no: line_no
  end
end
