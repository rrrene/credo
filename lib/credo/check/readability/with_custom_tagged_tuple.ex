defmodule Credo.Check.Readability.WithCustomTaggedTuple do
  use Credo.Check,
    id: "EX3032",
    category: :warning,
    base_priority: :low,
    explanations: [
      check: """
      Avoid using custom tags for error reporting from `with` macros.

      This code injects tuple_tag tags such as `:resource` and `:authz` for the purpose of error
      reporting.

          with {:resource, {:ok, resource}} <- {:resource, Resource.fetch(user)},
               {:authz, :ok} <- {:authz, Resource.authorize(resource, user)} do
            do_something_with(resource)
          else
            {:resource, _} -> {:error, :not_found}
            {:authz, _} -> {:error, :unauthorized}
          end

      Instead, extract each validation into a separate helper function which returns error
      information immediately:

          defp find_resource(user) do
            with :error <- Resource.fetch(user), do: {:error, :not_found}
          end

          defp authorize(resource, user) do
            with :error <- Resource.authorize(resource, user), do: {:error, :unauthorized}
          end

      At this point, the validation chain in `with` becomes clearer and easier to understand:

          with {:ok, resource} <- find_resource(user),
               :ok <- authorize(resource, user),
               do: do_something(user)

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params \\ []) do
    source_file
    |> find_issues()
    |> Enum.map(&issue_for(&1, IssueMeta.for(source_file, params)))
  end

  defp find_issues(source_file) do
    {_ast, issues} = Macro.prewalk(Credo.Code.ast(source_file), MapSet.new(), &traverse/2)

    Enum.sort_by(issues, &{&1.line, &1.column})
  end

  defp traverse({:with, _meta, args}, issues) do
    issues =
      args
      |> Stream.map(&tuple_tag/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.into(issues)

    {args, issues}
  end

  defp traverse(ast, state), do: {ast, state}

  defp tuple_tag({:<-, meta, [{tuple_tag, _}, {tuple_tag, _}]}) when is_atom(tuple_tag),
    do: %{tuple_tag: tuple_tag, line: meta[:line], column: meta[:column]}

  defp tuple_tag(_), do: nil

  defp issue_for(error, issue_meta) do
    format_issue(
      issue_meta,
      message:
        "Avoid using tagged tuples as placeholders in `with` (found: `#{inspect(error.tuple_tag)}`).",
      line_no: error.line,
      trigger: inspect(error.tuple_tag)
    )
  end
end
