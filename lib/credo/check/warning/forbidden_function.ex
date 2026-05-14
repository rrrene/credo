defmodule Credo.Check.Warning.ForbiddenFunction do
  use Credo.Check,
    id: "EX5033",
    base_priority: :high,
    category: :warning,
    param_defaults: [
      functions: []
    ],
    explanations: [
      check: """
      Some functions that are included by a package or public in your project
      may be hazardous if used directly.

      Use this check to forbid specific functions from being called directly
      by your application (while allowing other functions from the same module).

      This check is similar to `Credo.Check.Warning.ForbiddenModule`, but for
      specific functions within a module rather than the entire module.

      Example:

      `:erlang.binary_to_term/1` is vulnerable to arbitrary code execution exploits
      when deserializing untrusted data; you may want to point developers to
      `Plug.Crypto.non_executable_binary_to_term/2` instead, which
      disallows anonymous functions in the deserialized term.
      """,
      params: [
        functions: """
        List of `{module, function, error_message}` tuples specifying forbidden functions.

        Example:

            functions: [
              {:erlang, :binary_to_term, "Use `Plug.Crypto.non_executable_binary_to_term/2` instead."}
            ]
        """
      ]
    ]

  @impl Credo.Check
  def run(%SourceFile{} = source_file, params \\ []) do
    ctx =
      source_file
      |> Context.build(params, __MODULE__)
      |> Context.handle_param(:functions, fn functions ->
        Map.new(functions, fn {module, fun, message} ->
          if not is_atom(module), do: raise("Module name must be an atom; got #{inspect(module)}")
          if not is_atom(fun), do: raise("Function name must be an atom; got #{inspect(fun)}")

          {{module, fun}, message}
        end)
      end)

    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  # :erlang.binary_to_term(x)
  defp walk({{:., meta, [module, function]}, _, _} = ast, ctx)
       when is_atom(module) and is_atom(function) do
    issue = issue_for({module, function}, ctx, meta)

    {ast, put_issue(ctx, issue)}
  end

  # MyModule.my_function(...)
  defp walk({{:., meta, [{:__aliases__, _, module_parts}, function]}, _call_meta, _args} = ast, ctx)
       when is_atom(function) and is_list(module_parts) do
    ctx =
      if Enum.all?(module_parts, &is_atom/1) do
        module = Module.concat(module_parts)
        issue = issue_for({module, function}, ctx, meta)

        put_issue(ctx, issue)
      else
        ctx
      end

    {ast, ctx}
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp issue_for({mod, fun} = mod_fun_key, %{params: %{functions: functions}} = ctx, meta)
       when is_map_key(functions, mod_fun_key) do
    message = Map.get(functions, mod_fun_key)

    trigger = "#{inspect(mod)}.#{to_string(fun)}"
    message = message || "Calls to `#{trigger}` are not allowed."

    format_issue(ctx, message: message, trigger: trigger, line_no: meta[:line])
  end

  defp issue_for(_mod_fun, _forbidden_map, _meta), do: nil
end
