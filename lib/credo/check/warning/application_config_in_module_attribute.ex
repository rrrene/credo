defmodule Credo.Check.Warning.ApplicationConfigInModuleAttribute do
  use Credo.Check,
    id: "EX5001",
    base_priority: :high,
    tags: [:controversial],
    category: :warning,
    explanations: [
      check: """
      Module attributes are evaluated at compile time and not at run time. As
      a result, certain configuration read calls made in your module attributes
      may work as expected during local development, but may break once in a
      deployed context.

      This check analyzes all of the module attributes present within a module,
      and validates that there are no unsafe calls.

      These unsafe calls include:

      - `Application.fetch_env/2`
      - `Application.fetch_env!/2`
      - `Application.get_all_env/1`
      - `Application.get_env/3`
      - `Application.get_env/2`

      As of Elixir 1.10 you can leverage `Application.compile_env/3` and
      `Application.compile_env!/2` if you wish to set configuration at
      compile time using module attributes.
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params \\ []) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:@, _meta, [attribute_definition]} = ast, ctx) do
    case traverse_attribute(attribute_definition) do
      nil -> {ast, ctx}
      {attribute, call} -> {ast, put_issue(ctx, issue_for(attribute, call, ctx))}
    end
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp traverse_attribute({attribute, _, _} = ast) do
    case Macro.prewalk(ast, nil, &get_forbidden_call/2) do
      {_ast, nil} -> nil
      {_ast, call} -> {attribute, call}
    end
  end

  defp traverse_attribute(_ast) do
    nil
  end

  defp get_forbidden_call(
         {{:., _, [{:__aliases__, meta, [:Application]}, :fetch_env]}, _meta, _args} = ast,
         _acc
       ) do
    {ast, {meta, "Application.fetch_env/2", "Application.fetch_env"}}
  end

  defp get_forbidden_call(
         {{:., _, [{:__aliases__, meta, [:Application]}, :fetch_env!]}, _meta, _args} = ast,
         _acc
       ) do
    {ast, {meta, "Application.fetch_env!/2", "Application.fetch_env"}}
  end

  defp get_forbidden_call(
         {{:., _, [{:__aliases__, meta, [:Application]}, :get_all_env]}, _meta, _args} = ast,
         _acc
       ) do
    {ast, {meta, "Application.get_all_env/1", "Application.get_all_env"}}
  end

  defp get_forbidden_call(
         {{:., _, [{:__aliases__, meta, [:Application]}, :get_env]}, _meta, args} = ast,
         _acc
       ) do
    {ast, {meta, "Application.get_env/#{length(args)}", "Application.get_env"}}
  end

  defp get_forbidden_call(ast, acc) do
    {ast, acc}
  end

  defp issue_for(attribute, {meta, call, trigger}, ctx) do
    format_issue(ctx,
      message:
        "Module attribute @#{Atom.to_string(attribute)} makes use of unsafe Application configuration call #{call}",
      trigger: trigger,
      line_no: meta[:line],
      column: meta[:column]
    )
  end
end
