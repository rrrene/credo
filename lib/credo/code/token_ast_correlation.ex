defmodule Credo.Code.TokenAstCorrelation do
  #
  #
  #
  alias Credo.Code.Token

  def ast(source) do
    {:ok, ast} = Credo.Code.ast(source)

    #    tokens =
    #      Credo.Code.to_tokens(source)
    #      |> Enum.group_by(fn token ->
    #        {line_no, _, _, _} = Token.position(token)
    #
    #        line_no
    #      end)
    #
    #    lines = Credo.Code.to_lines(source) |> Enum.into(%{})

    ast
  end

  #

  def find_tokens_in_ast(wanted_token, tokens, ast) do
    {prev, current, next} = find_current_prev_next_token(tokens, wanted_token)
    position = Credo.Code.Token.position(current)

    {line_no_start, col_start, line_no_end, _col_end} = position

    Credo.Code.prewalk(ast, &traverse_ast_for_token(&1, &2, wanted_token))
    |> IO.inspect(label: "prewalk")
  end

  #

  defp traverse_ast_for_token({_name, meta, _arguments} = ast, acc, token) do
    {line_no_start, col_start, _line_no_end, _col_end} = Credo.Code.Token.position(token)

    if meta[:line] == line_no_start && meta[:column] == col_start do
      {nil, acc ++ [ast]}
    else
      {ast, acc}
    end
  end

  defp traverse_ast_for_token(ast, acc, _token) do
    {ast, acc}
  end

  #

  defp find_current_prev_next_token(tokens, token) do
    [result] = traverse_prev_current_next(tokens, &matching_location(token, &1, &2, &3, &4), [])

    result
  end

  defp traverse_prev_current_next(tokens, callback, acc) do
    tokens
    |> case do
      [prev | [current | [next | rest]]] ->
        acc = callback.(prev, current, next, acc)

        traverse_prev_current_next([current | [next | rest]], callback, acc)

      _ ->
        acc
    end
  end

  defp matching_location(current, prev, current, next, acc) do
    acc ++ [{prev, current, next}]
  end

  defp matching_location(_, _prev, _current, _next, acc) do
    acc
  end
end
