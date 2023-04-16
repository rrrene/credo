defmodule Credo.Check.Readability.DependencyOrder do
  use Credo.Check,
    id: "",
    base_priority: :low,
    explanations: [
      check: """

      """
    ]

  alias Credo.Code.Name

  @doc false
  @impl true
  def run(%SourceFile{filename: "mix.exs"} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  def run(%SourceFile{} = _source_file, _params) do
    []
  end

  defp traverse({:defp, _, [{:deps, meta, _}, [do: deps]]} = ast, issues, issue_meta) do
    result = Enum.reduce_while(deps, true, &compare/2)

    case result do
      {:error, deps_name} ->
        # credo:disable-for-next-line Credo.Check.Refactor.AppendSingleItem
        {ast, issues ++ [issue_for(deps_name, meta[:line], issue_meta)]}

      {:error, deps_name, deps_meta} ->
        # credo:disable-for-next-line Credo.Check.Refactor.AppendSingleItem
        {ast, issues ++ [issue_for(deps_name, deps_meta[:line], issue_meta)]}

      _atom ->
        {ast, issues}
    end
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp compare({deps_name, _version}, true), do: {:cont, deps_name}
  defp compare({:{}, _, [deps_name, _version, _params]}, true), do: {:cont, deps_name}
  defp compare({deps_name, _version}, prev) when deps_name > prev, do: {:cont, deps_name}

  defp compare({:{}, _, [deps_name, _version, _params]}, prev) when deps_name > prev,
    do: {:cont, deps_name}

  defp compare({deps_name, _version}, _prev), do: {:halt, {:error, deps_name}}

  defp compare({:{}, meta, [deps_name, _version, _params]}, _prev),
    do: {:halt, {:error, deps_name, meta}}

  defp issue_for(deps_name, line_no, issue_meta) do
    format_issue(
      issue_meta,
      message: "Mix dependency #{deps_name} not sorted correctly",
      trigger: deps_name,
      line_no: line_no
    )
  end
end
