defmodule Credo.Check.Readability.WithCustomTaggedTuple do
  use Credo.Check,
    category: :warning,
    base_priority: :low,
    explanations: [
      check: """
      Avoid using custom tags for error reporting from `with` macros.

      This code injects placeholder tags such as `:resource` and `:authz` for the purpose of error
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
    |> errors()
    |> Enum.map(&credo_error(&1, IssueMeta.for(source_file, params)))
  end

  defp errors(source_file) do
    {_ast, errors} = Macro.prewalk(Credo.Code.ast(source_file), MapSet.new(), &traverse/2)
    Enum.sort_by(errors, &{&1.line, &1.column})
  end

  defp traverse({:with, _meta, args}, errors) do
    errors =
      args
      |> Stream.map(&placeholder/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.into(errors)

    {args, errors}
  end

  defp traverse(ast, state), do: {ast, state}

  defp placeholder({:<-, meta, [{placeholder, _}, {placeholder, _}]}) when is_atom(placeholder),
    do: %{placeholder: placeholder, line: meta[:line], column: meta[:column]}

  defp placeholder(_), do: nil

  defp credo_error(error, issue_meta) do
    format_issue(
      issue_meta,
      message: "Invalid usage of placeholder `#{inspect(error.placeholder)}` in with",
      line_no: error.line,
      column: error.column
    )
  end
end
