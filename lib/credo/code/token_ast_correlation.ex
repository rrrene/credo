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
  def find_tokens_in_ast(wanted_token, ast)

  if Version.match?(System.version(), ">= 1.6.0-rc") do
    # Elixir >= 1.6.0
    def find_tokens_in_ast(wanted_token, ast) do
      do_find_tokens_in_ast(wanted_token, ast)
    end
  else
    # Elixir <= 1.5.x
    def find_tokens_in_ast(wanted_token, ast) do
      nil
    end
  end

  defp do_find_tokens_in_ast(wanted_token, ast) do
    Credo.Code.prewalk(ast, &traverse_ast_for_token(&1, &2, wanted_token))
  end

  #

  defp traverse_ast_for_token({_name, meta, _arguments} = ast, acc, token) do
    {line_no_start, col_start, _line_no_end, _col_end} = Token.position(token)

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

  defp matching_location(current, prev, current, next, acc) do
    acc ++ [{prev, current, next}]
  end

  defp matching_location(_, _prev, _current, _next, acc) do
    acc
  end
end
