defmodule Credo.Check.Readability.PreferUnquotedAtoms do
  use Credo.Check,
    run_on_all: true,
    base_priority: :high,
    elixir_version: "< 1.7.0-dev",
    explanations: [
      check: """
      Prefer unquoted atoms unless quotes are necessary.
      This is helpful because a quoted atom can be easily mistaken for a string.

          # preferred

          :x
          [x: 1]
          %{x: 1}

          # NOT preferred

          :"x"
          ["x": 1]
          %{"x": 1}

      The primary case where this can become an issue is when using atoms or
      strings for keys in a Map or Keyword list.

      For example, this:

          %{"x": 1}

      Can easily be mistaken for this:

          %{"x" => 1}

      Because a string key cannot be used to access a value with the equivalent
      atom key, this can lead to subtle bugs which are hard to discover.

      Like all `Readability` issues, this one is not a technical concern.
      The code will behave identical in both ways.
      """
    ]

  @token_types [:atom_unsafe, :kw_identifier_unsafe]

  @doc false
  @impl true
  # TODO: consider for experimental check front-loader (tokens)
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    source_file
    |> Credo.Code.to_tokens()
    |> Enum.reduce([], &find_issues(&1, &2, issue_meta))
    |> Enum.reverse()
  end

  for type <- @token_types do
    defp find_issues(
           {unquote(type), {line_no, column, _}, token},
           issues,
           issue_meta
         ) do
      case safe_atom_name(token) do
        nil ->
          issues

        atom ->
          [issue_for(issue_meta, atom, line_no, column) | issues]
      end
    end
  end

  defp find_issues(_token, issues, _issue_meta) do
    issues
  end

  # "safe atom" here refers to a quoted atom not containing an interpolation
  defp safe_atom_name(token) when is_list(token) do
    if Enum.all?(token, &is_binary/1) do
      token
      |> Enum.join()
      |> safe_atom_name()
    end
  end

  defp safe_atom_name(token) when is_binary(token) do
    ':#{token}'
    |> :elixir_tokenizer.tokenize(1, [])
    |> safe_atom_name(token)
  end

  defp safe_atom_name(_), do: nil

  # Elixir >= 1.6.0
  defp safe_atom_name({:ok, [{:atom, {_, _, _}, atom} | _]}, token) do
    if token == Atom.to_string(atom) do
      atom
    end
  end

  # Elixir <= 1.5.x
  defp safe_atom_name({:ok, _, _, [{:atom, _, atom} | _]}, token) do
    if token == Atom.to_string(atom) do
      atom
    end
  end

  defp issue_for(issue_meta, atom, line_no, column) do
    trigger = ~s[:"#{atom}"]

    format_issue(
      issue_meta,
      message: "Use unquoted atom `#{inspect(atom)}` rather than quoted atom `#{trigger}`.",
      trigger: trigger,
      line_no: line_no,
      column: column
    )
  end
end
