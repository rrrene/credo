defmodule Credo.Check.Warning.ForbiddenFunction do
  use Credo.Check,
    id: "EX5030",
    base_priority: :high,
    category: :warning,
    param_defaults: [
      functions: []
    ],
    explanations: [
      check: """
      Some functions may be hazardous if used directly. Use this check to
      forbid specific functions from being called directly by your application,
      while allowing other functions in the same module.

      This check is similar to `Credo.Check.Warning.ForbiddenModule`, but for
      specific functions within a module rather than the entire module.

      For example, `:erlang.binary_to_term/1` is vulnerable to arbitrary code
      execution exploits when deserializing untrusted data; you may want to point
      developers to `Plug.Crypto.non_executable_binary_to_term/2` instead, which
      disallows anonymous functions in the deserialized term.
      """,
      params: [
        functions: """
        List of `{module, function, error_message}` tuples specifying forbidden functions.

        Example:

            functions: [
              {:erlang, :binary_to_term, "Use Plug.Crypto.non_executable_binary_to_term/2 instead."}
            ]
        """
      ]
    ]

  @doc false
  @impl Credo.Check
  def run(%SourceFile{} = source_file, params \\ []) do
    case Params.get(params, :functions, __MODULE__) do
      [_ | _] = functions ->
        issue_meta = IssueMeta.for(source_file, params)
        forbidden_map = build_forbidden_map(functions)
        Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta, forbidden_map))

      [] ->
        []
    end
  end

  defp build_forbidden_map(functions) do
    Map.new(functions, fn {module, fun, message} ->
      if not is_atom(module), do: raise("Module name must be an atom; got #{inspect(module)}")
      if not is_atom(fun), do: raise("Function name must be an atom; got #{inspect(fun)}")
      {{module, fun}, to_string(message)}
    end)
  end

  # Handle calls to erlang modules like :erlang.binary_to_term(x)
  defp traverse({{:., meta, [module, function]}, _, _} = ast, issues, issue_meta, forbidden_map)
       when is_atom(module) and is_atom(function) do
    {ast, append_issue_if_forbidden({module, function}, forbidden_map, issues, issue_meta, meta)}
  end

  # Handle calls to Elixir modules like MyModule.my_function(...)
  defp traverse(
         {{:., meta, [{:__aliases__, _, module_parts}, function]}, _call_meta, _args} = ast,
         issues,
         issue_meta,
         forbidden_map
       )
       when is_atom(function) and is_list(module_parts) do
    issues =
      if Enum.all?(module_parts, &is_atom/1) do
        module = Credo.Code.Name.full(module_parts)
        append_issue_if_forbidden({module, function}, forbidden_map, issues, issue_meta, meta)
      else
        issues
      end

    {ast, issues}
  end

  defp traverse(ast, issues, _issue_meta, _forbidden_map), do: {ast, issues}

  defp append_issue_if_forbidden(mod_fun, forbidden_map, issues, issue_meta, meta)
       when is_map_key(forbidden_map, mod_fun) do
    message = Map.get(forbidden_map, mod_fun)
    [create_issue(issue_meta, meta[:line], mod_fun, message) | issues]
  end

  defp append_issue_if_forbidden(_mod_fun, _forbidden_map, issues, _issue_meta, _meta), do: issues

  defp create_issue(issue_meta, line_no, {mod, fun}, message) do
    trigger = "#{inspect(mod)}.#{to_string(fun)}"

    format_issue(
      issue_meta,
      message: "#{trigger} is forbidden: #{message}",
      trigger: trigger,
      line_no: line_no
    )
  end
end
