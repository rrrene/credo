defmodule Credo.Check.Warning.UnsafeToAtom do
  use Credo.Check,
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
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse({:@, _, _}, issues, _) do
    {nil, issues}
  end

  defp traverse({{:., _loc, call}, meta, args} = ast, issues, issue_meta) do
    case get_forbidden_call(call, args) do
      {bad, suggestion} ->
        {ast, issues_for_call(bad, suggestion, meta, issue_meta, issues)}

      nil ->
        {ast, issues}
    end
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp get_forbidden_call([:erlang, :list_to_atom], [_]) do
    {":erlang.list_to_atom/1", ":erlang.list_to_existing_atom/1"}
  end

  defp get_forbidden_call([:erlang, :binary_to_atom], [_, _]) do
    {":erlang.binary_to_atom/2", ":erlang.binary_to_existing_atom/2"}
  end

  defp get_forbidden_call([{:__aliases__, _, [:String]}, :to_atom], [_]) do
    {"String.to_atom/1", "String.to_existing_atom/1"}
  end

  defp get_forbidden_call([{:__aliases__, _, [:List]}, :to_atom], [_]) do
    {"List.to_atom/1", "List.to_existing_atom/1"}
  end

  defp get_forbidden_call([{:__aliases__, _, [:Module]}, :concat], [_]) do
    {"Module.concat/1", "Module.safe_concat/1"}
  end

  defp get_forbidden_call([{:__aliases__, _, [:Module]}, :concat], [_, _]) do
    {"Module.concat/2", "Module.safe_concat/2"}
  end

  defp get_forbidden_call([{:__aliases__, _, [:Jason]}, decode], args)
       when decode in [:decode, :decode!] do
    args
    |> Enum.any?(fn arg -> Keyword.keyword?(arg) and Keyword.get(arg, :keys) == :atoms end)
    |> if do
      {"Jason.#{decode}(..., keys: :atoms)", "Jason.#{decode}(..., keys: :atoms!)"}
    else
      nil
    end
  end

  defp get_forbidden_call(_, _) do
    nil
  end

  defp issues_for_call(call, suggestion, meta, issue_meta, issues) do
    options = [
      message: "Prefer #{suggestion} over #{call} to avoid creating atoms at runtime",
      trigger: call,
      line_no: meta[:line]
    ]

    [format_issue(issue_meta, options) | issues]
  end
end
