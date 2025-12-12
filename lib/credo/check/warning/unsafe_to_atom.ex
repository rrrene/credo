defmodule Credo.Check.Warning.UnsafeToAtom do
  use Credo.Check,
    id: "EX5016",
    base_priority: :high,
    category: :warning,
    tags: [:controversial],
    explanations: [
      check: """
      Creating atoms from unknown or external sources dynamically is a potentially
      unsafe operation because atoms are not garbage-collected by the runtime.

      Creating an atom from a string or charlist should be done by using

          String.to_existing_atom(string)

      or

          List.to_existing_atom(charlist)

      Module aliases should be constructed using

          Module.safe_concat(prefix, suffix)

      or

          Module.safe_concat([prefix, infix, suffix])

      Jason.decode/Jason.decode! should be called using `keys: :atoms!` (*not* `keys: :atoms`):

          Jason.decode(str, keys: :atoms!)

      or `:keys` should be omitted (which defaults to `:strings`):

          Jason.decode(str)

      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:@, _, _}, ctx) do
    {nil, ctx}
  end

  defp walk({:unquote, _, [_ | _] = _args}, ctx) do
    {nil, ctx}
  end

  # module.unquote(:"some_atom")
  defp walk({{:., _, [_, :unquote]}, _, [_ | _] = _args}, ctx) do
    {nil, ctx}
  end

  defp walk({:|>, _meta1, [_lhs, {{:., _meta2, call}, meta, args}]} = ast, ctx) do
    case get_forbidden_pipe(call, args) do
      {bad, suggestion, trigger} ->
        {ast, put_issue(ctx, issue_for(ctx, meta, bad, suggestion, trigger))}

      nil ->
        {ast, ctx}
    end
  end

  defp walk({{:., _loc, call}, meta, args} = ast, ctx) do
    case get_forbidden_call(call, args) do
      {bad, suggestion, trigger} ->
        {ast, put_issue(ctx, issue_for(ctx, meta, bad, suggestion, trigger))}

      nil ->
        {ast, ctx}
    end
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp get_forbidden_call([:erlang, :list_to_atom], [_]) do
    {":erlang.list_to_atom/1", ":erlang.list_to_existing_atom/1", ":erlang.list_to_atom"}
  end

  defp get_forbidden_call([:erlang, :binary_to_atom], [_, _]) do
    {":erlang.binary_to_atom/2", ":erlang.binary_to_existing_atom/2", ":erlang.binary_to_atom"}
  end

  defp get_forbidden_call([{:__aliases__, _, [:String]}, :to_atom], [_]) do
    {"String.to_atom/1", "String.to_existing_atom/1", "String.to_atom"}
  end

  defp get_forbidden_call([{:__aliases__, _, [:List]}, :to_atom], [_]) do
    {"List.to_atom/1", "List.to_existing_atom/1", "List.to_atom"}
  end

  defp get_forbidden_call([{:__aliases__, _, [:Module]}, :concat], [_]) do
    {"Module.concat/1", "Module.safe_concat/1", "Module.concat"}
  end

  defp get_forbidden_call([{:__aliases__, _, [:Module]}, :concat], [_, _]) do
    {"Module.concat/2", "Module.safe_concat/2", "Module.concat"}
  end

  defp get_forbidden_call([{:__aliases__, _, [:Jason]}, decode], args)
       when decode in [:decode, :decode!] do
    args
    |> Enum.any?(fn arg -> Keyword.keyword?(arg) and Keyword.get(arg, :keys) == :atoms end)
    |> if do
      {"Jason.#{decode}(..., keys: :atoms)", "Jason.#{decode}(..., keys: :atoms!)",
       "Jason.#{decode}"}
    else
      nil
    end
  end

  defp get_forbidden_call(_, _) do
    nil
  end

  defp get_forbidden_pipe([:erlang, :list_to_atom], []) do
    {":erlang.list_to_atom/1", ":erlang.list_to_existing_atom/1", ":erlang.list_to_atom"}
  end

  defp get_forbidden_pipe([:erlang, :binary_to_atom], [_]) do
    {":erlang.binary_to_atom/2", ":erlang.binary_to_existing_atom/2", ":erlang.binary_to_atom"}
  end

  defp get_forbidden_pipe([{:__aliases__, _, [:String]}, :to_atom], []) do
    {"String.to_atom/1", "String.to_existing_atom/1", "String.to_atom"}
  end

  defp get_forbidden_pipe([{:__aliases__, _, [:List]}, :to_atom], []) do
    {"List.to_atom/1", "List.to_existing_atom/1", "List.to_atom"}
  end

  defp get_forbidden_pipe([{:__aliases__, _, [:Module]}, :concat], []) do
    {"Module.concat/1", "Module.safe_concat/1", "Module.concat"}
  end

  defp get_forbidden_pipe(_, _) do
    nil
  end

  defp issue_for(ctx, meta, call, suggestion, trigger) do
    format_issue(ctx,
      message: "Prefer #{suggestion} over #{call} to avoid creating atoms at runtime.",
      trigger: trigger,
      line_no: meta[:line]
    )
  end
end
