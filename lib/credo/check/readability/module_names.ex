defmodule Credo.Check.Readability.ModuleNames do
  use Credo.Check,
    base_priority: :high,
    param_defaults: [
      allow: []
    ],
    explanations: [
      check: """
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
      """,
      params: [
        allow:
          "List of allowed name segment patterns e.g. `[~r/Sample_Module/, \"Sample_Module\"]`"
      ]
    ]

  alias Credo.Code.Name

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)
    allowed_patterns = Credo.Check.Params.get(params, :allow, __MODULE__)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta, allowed_patterns))
  end

  defp traverse({:defmodule, _meta, arguments} = ast, issues, issue_meta, allowed_patterns) do
    {ast, issues_for_def(arguments, issues, issue_meta, allowed_patterns)}
  end

  defp traverse(ast, issues, _issue_meta, _allowed_patterns) do
    {ast, issues}
  end

  defp issues_for_def(body, issues, issue_meta, allowed_patterns) do
    case Enum.at(body, 0) do
      {:__aliases__, meta, names} ->
        names
        |> Enum.filter(&String.Chars.impl_for/1)
        |> Enum.join(".")
        |> issues_for_name(meta, issues, issue_meta, allowed_patterns)

      _ ->
        issues
    end
  end

  defp issues_for_name(name, meta, issues, issue_meta, allowed_patterns) do
    segments =
      name
      |> to_string
      |> String.split(".")

    all_correct? =
      Enum.all?(segments, fn segment ->
         allowed_segment?(allowed_patterns, segment) or Name.pascal_case?(segment)
      end)

    if all_correct? do
      issues
    else
      [issue_for(issue_meta, meta[:line], name) | issues]
    end
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message: "Module names should be written in PascalCase.",
      trigger: trigger,
      line_no: line_no
    )
  end

  defp allowed_segment?([], _segment), do: false

  defp allowed_segment?(allowed_patterns, segment) do
    Enum.any?(allowed_patterns, fn
      %Regex{} = pattern ->
        String.match?(segment, pattern)

      module_name ->
        String.equivalent?(segment, to_string(module_name))
    end)
  end
end
