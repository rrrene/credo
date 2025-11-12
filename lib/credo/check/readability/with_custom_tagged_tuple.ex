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
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:with, _meta, args}, ctx) do
    issues =
      args
      |> Stream.map(&issue_or_nil(&1, ctx))
      |> Enum.reject(&is_nil/1)

    {args, put_issue(ctx, issues)}
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp issue_or_nil({:<-, meta, [{tuple_tag, _}, {tuple_tag, _}]}, ctx) when is_atom(tuple_tag) do
    issue_for(tuple_tag, meta, ctx)
  end

  defp issue_or_nil(_, _), do: nil

  defp issue_for(tuple_tag, meta, ctx) do
    format_issue(
      ctx,
      message:
        "Avoid using tagged tuples as placeholders in `with` (found: `#{inspect(tuple_tag)}`).",
      trigger: inspect(tuple_tag),
      line_no: meta[:line]
    )
  end
end
