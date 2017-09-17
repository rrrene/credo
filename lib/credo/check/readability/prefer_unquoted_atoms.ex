defmodule Credo.Check.Readability.PreferUnquotedAtoms do
  @moduledoc """
  Prefer unquoted atoms unless quotes are necessary.
  This is helpful because a quoted atom can be easily mistaken for a string.

      # prefered
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

  @explanation [check: @moduledoc]

  @token_types [:atom_unsafe, :kw_identifier_unsafe]

  use Credo.Check, run_on_all: true, base_priority: :high

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    source_file
    |> Credo.Code.to_tokens()
    |> Enum.reduce([], &find_issues(&1, &2, issue_meta))
    |> Enum.reverse()
  end

  for type <- @token_types do
    defp find_issues({unquote(type), {line_no, column, _}, token}, issues, issue_meta) do
      case safe_atom_name(token) do
        {:ok, atom} ->
          [issue_for(issue_meta, atom, line_no, column) | issues]
        :error ->
          issues
      end
    end
  end

  defp find_issues(_token, issues, _issue_meta) do
    issues
  end

  defp safe_atom_name(token) when is_list(token) do
    if Enum.all?(token, &is_binary/1) do
      token
      |> Enum.join()
      |> safe_atom_name()
    else
      :error
    end
  end
  defp safe_atom_name(token) when is_binary(token) do
    case :elixir_tokenizer.tokenize(':#{token}', 1, []) do
      {:ok, _, _, [{:atom, _, atom}]} ->
        if is_atom(atom) and token == Atom.to_string(atom) do
          {:ok, atom}
        else
          :error
        end
      _ -> :error
    end
  end
  defp safe_atom_name(_), do: :error

  defp issue_for(issue_meta, atom, line_no, column) do
    trigger = ~s[:"#{atom}"]
    format_issue issue_meta,
      message: "Use unquoted atom `#{inspect atom}` rather than quoted atom `#{trigger}`.",
      trigger: trigger,
      line_no: line_no,
      column: column
  end
end
