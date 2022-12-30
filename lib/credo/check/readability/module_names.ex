defmodule Credo.Check.Readability.ModuleNames do
  use Credo.Check,
    id: "EX3010",
    base_priority: :high,
    param_defaults: [
      ignore: []
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
        ignore:
          "List of ignored module names and patterns e.g. `[~r/Sample_Module/, \"Credo.Sample_Module\"]`"
      ]
    ]

  alias Credo.Code.Name

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)
    ignored_patterns = Credo.Check.Params.get(params, :ignore, __MODULE__)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta, ignored_patterns))
  end

  defp traverse({:defmodule, _meta, arguments} = ast, issues, issue_meta, ignored_patterns) do
    {ast, issues_for_def(arguments, issues, issue_meta, ignored_patterns)}
  end

  defp traverse(ast, issues, _issue_meta, _ignored_patterns) do
    {ast, issues}
  end

  defp issues_for_def(body, issues, issue_meta, ignored_patterns) do
    case Enum.at(body, 0) do
      {:__aliases__, meta, names} ->
        names
        |> Enum.filter(&String.Chars.impl_for/1)
        |> Enum.join(".")
        |> issues_for_name(meta, issues, issue_meta, ignored_patterns)

      _ ->
        issues
    end
  end

  defp issues_for_name(name, meta, issues, issue_meta, ignored_patterns) do
    module_name = Name.full(name)

    pascal_case? =
      module_name
      |> String.split(".")
      |> Enum.all?(&Name.pascal_case?/1)

    if pascal_case? or ignored_module?(ignored_patterns, module_name) do
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

  defp ignored_module?([], _module_name), do: false

  defp ignored_module?(ignored_patterns, module_name) do
    Enum.any?(ignored_patterns, fn
      %Regex{} = pattern ->
        String.match?(module_name, pattern)

      name when is_atom(name) ->
        module_name == Credo.Code.Name.full(name)

      name ->
        module_name == name
    end)
  end
end
