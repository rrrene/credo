defmodule Credo.Check.Readability.AliasAs do
  use Credo.Check,
    base_priority: :low,
    tags: [:experimental],
    param_defaults: [
      ignore: []
    ],
    explanations: [
      check: """
      Aliases which are not completely renamed using the `:as` option are easier to follow.

          # preferred

          def MyModule do
            alias MyApp.Module1

            def my_function(foo) do
              Module1.run(foo)
            end
          end

          # NOT preferred

          def MyModule do
            alias MyApp.Module1, as: M1

            def my_function(foo) do
              # what the heck is `M1`?
              M1.run(foo)
            end
          end

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """,
      params: [
        ignore: "List of modules to ignore and allow to `alias Module, as: ...`"
      ]
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ignore = Params.get(params, :ignore, __MODULE__)

    source_file
    |> Credo.Code.prewalk(&traverse(&1, &2, IssueMeta.for(source_file, params), ignore))
    |> Enum.reverse()
  end

  defp traverse(ast, issues, issue_meta, ignore),
    do: {ast, add_issue(issues, issue(ast, issue_meta, ignore))}

  defp add_issue(issues, nil), do: issues
  defp add_issue(issues, issue), do: [issue | issues]

  defp issue({:alias, _, [{:__MODULE__, _, nil}, [as: {_, meta, _}]]}, issue_meta, ignore) do
    line = meta[:line]
    {Credo.IssueMeta, source_file, _check_params} = issue_meta
    {_def, module_name} = Check.scope_for(source_file, line: line)
    module = Module.concat([module_name])

    if :__MODULE__ not in ignore and module not in ignore do
      issue_for(issue_meta, line, inspect(:__MODULE__))
    else
      nil
    end
  end

  defp issue({:alias, _, [{_, _, original}, [as: {_, meta, _}]]}, issue_meta, ignore) do
    module = Module.concat(original)

    if module not in ignore do
      issue_for(issue_meta, meta[:line], inspect(module))
    else
      nil
    end
  end

  defp issue(_ast, _issue_meta, _ignore), do: nil

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message: "Avoid using the :as option with alias.",
      trigger: trigger,
      line_no: line_no
    )
  end
end
