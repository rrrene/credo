defmodule Credo.Check.Readability.ModuleDoc do
  @moduledoc """
  Every module should contain comprehensive documentation.

  Many times a sentence or two in plain english, explaining why the module
  exists, will suffice. Documenting your train of thought this way will help
  both your co-workers and your future-self.

  Other times you will want to elaborate even further and show some
  examples of how the module's functions can and should be used.

  In some cases however, you might not want to document things about a module,
  e.g. it is part of a private API inside your project. Since Elixir prefers
  explicitness over implicit behaviour, you should "tag" these modules with

      @moduledoc false

  to make it clear that there is no intention in documenting it.
  """

  @explanation [check: @moduledoc]
  @default_params [
    ignore_names: [
      ~r/(\.\w+Controller|\.Endpoint|\.Mixfile|\.Repo|\.Router|\.\w+Socket|\w+Test|\.\w+View)$/
    ]
  ]

  alias Credo.Code.Module

  use Credo.Check

  def run(%SourceFile{ast: ast} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    ignore_names = params |> Params.get(:ignore_names, @default_params)

    Credo.Code.prewalk(ast, &traverse(&1, &2, issue_meta, ignore_names))
  end

  defp traverse({:defmodule, meta, _arguments} = ast, issues, issue_meta, ignore_names) do
    exception? = Module.exception?(ast)
    case Module.attribute(ast, :moduledoc)  do
      {:error, _} when not exception? ->
        mod_name = Module.name(ast)
        if mod_name |> matches?(ignore_names) do
          {ast, issues}
        else
          {ast, [issue_for(issue_meta, meta[:line], mod_name)] ++ issues}
        end
      _ ->
        {ast, issues}
    end
  end
  defp traverse(ast, issues, _issue_meta, _ignore_names) do
    {ast, issues}
  end

  defp matches?(name, patterns) when is_list(patterns) do
    patterns |> Enum.any?(&matches?(name, &1))
  end
  defp matches?(name, string) when is_binary(string) do
    name |> String.contains?(string)
  end
  defp matches?(name, regex) do
    String.match?(name, regex)
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue issue_meta,
      message: "Modules should have a @moduledoc tag.",
      trigger: trigger,
      line_no: line_no
  end
end
