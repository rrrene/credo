defmodule Credo.Code.TokenAstCorrelation do
  # Elixir >= 1.6.0
  def find_tokens_in_ast(wanted_token, ast) do
    Credo.Code.prewalk(ast, &traverse_ast_for_token(&1, &2, wanted_token))
  end

  defp traverse_ast_for_token({:., meta, arguments} = ast, acc, token)
       when is_list(arguments) do
    {line_no_start, col_start, _line_no_end, _col_end} = Credo.Code.Token.position(token)

    if meta[:line] == line_no_start && meta[:column] == col_start - 1 do
      {nil, acc ++ [ast]}
    else
      {ast, acc}
    end
  end

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
end
