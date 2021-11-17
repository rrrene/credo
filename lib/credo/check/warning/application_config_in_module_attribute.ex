defmodule Credo.Check.Warning.ApplicationConfigInModuleAttribute do
  use Credo.Check,
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
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse({:@, meta, [attribute_definition]} = ast, issues, issue_meta) do
    case traverse_attribute(attribute_definition) do
      nil ->
        {ast, issues}

      {attribute, call} ->
        {ast, issues_for_call(attribute, call, meta, issue_meta, issues)}
    end
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp traverse_attribute({attribute, _, _} = ast) do
    case Macro.prewalk(ast, nil, &get_forbidden_call/2) do
      {_ast, nil} ->
        nil

      {_ast, call} ->
        {attribute, call}
    end
  end

  defp traverse_attribute(_ast) do
    nil
  end

  defp get_forbidden_call(
         {{:., _, [{:__aliases__, _, [:Application]}, :fetch_env]}, _meta, _args} = ast,
         _acc
       ) do
    {ast, "Application.fetch_env/2"}
  end

  defp get_forbidden_call(
         {{:., _, [{:__aliases__, _, [:Application]}, :fetch_env!]}, _meta, _args} = ast,
         _acc
       ) do
    {ast, "Application.fetch_env!/2"}
  end

  defp get_forbidden_call(
         {{:., _, [{:__aliases__, _, [:Application]}, :get_all_env]}, _meta, _args} = ast,
         _acc
       ) do
    {ast, "Application.get_all_env/1"}
  end

  defp get_forbidden_call(
         {{:., _, [{:__aliases__, _, [:Application]}, :get_env]}, _meta, args} = ast,
         _acc
       ) do
    {ast, "Application.get_env/#{length(args)}"}
  end

  defp get_forbidden_call(ast, acc) do
    {ast, acc}
  end

  defp issues_for_call(attribute, call, meta, issue_meta, issues) do
    options = [
      message:
        "Module attribute @#{Atom.to_string(attribute)} makes use of unsafe Application configuration call #{call}",
      trigger: call,
      line_no: meta[:line]
    ]

    [format_issue(issue_meta, options) | issues]
  end
end
