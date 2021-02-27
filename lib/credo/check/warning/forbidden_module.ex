defmodule Credo.Check.Warning.ForbiddenModule do
  @moduledoc """
    Checks for use of a list of modules that are not allowed
  """

  alias Credo.Code

  use Credo.Check,
    base_priority: :high,
    category: :warning,
    param_defaults: [modules: []],
    explanations: [
      check: """
      These modules are are forbidden.
      """,
      params: [modules: "This check warns about modules that can not be used."]
    ]

  @impl Credo.Check
  def run(source_file = %SourceFile{}, params) do
    modules =
      params
      |> Params.get(:modules, __MODULE__)
      |> List.wrap()

    Code.prewalk(source_file, &traverse(&1, &2, modules, IssueMeta.for(source_file, params)))
  end

  defp traverse(ast = {:__aliases__, meta, module}, issues, forbidden_modules, issue_meta) do
    # Catches import and alias statements for a forbidden module
    if forbidden_module?(module, forbidden_modules) do
      {ast, [issue_for(issue_meta, meta[:line], module) | issues]}
    else
      {ast, issues}
    end
  end

  defp traverse(ast, issues, _, _), do: {ast, issues}

  defp forbidden_module?(module, forbidden_modules) do
    Enum.all?(module, &is_atom/1) && Enum.member?(forbidden_modules, Module.concat(module))
  end

  defp issue_for(issue_meta, line_no, module) do
    trigger = module |> Module.concat() |> mod_string()

    format_issue(
      issue_meta,
      message: "The `#{trigger}` module is not allowed.",
      trigger: trigger,
      line_no: line_no
    )
  end

  defp mod_string(module), do: ~r/Elixir\./ |> Regex.replace(to_string(module), "")
end
