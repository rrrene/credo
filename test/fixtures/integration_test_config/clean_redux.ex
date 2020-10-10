defmodule X do
  defp escape_charlist(reversed_result, [?" | remainder], needs_quote?),
    do: escape_charlist('"\\' ++ reversed_result, remainder, needs_quote?)

  @doc ~S"""
  Escape a subsection name before saving.
  """
  def escape_subsection(""), do: "\"\""

  def escape_subsection(x) when is_binary(x) do
    x
    |> String.to_charlist()
    |> escape_subsection_impl([])
    |> Enum.reverse()
    |> to_quoted_string()
  end

  defp to_quoted_string(s), do: ~s["#{s}"]
end
