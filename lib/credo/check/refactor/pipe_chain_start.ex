defmodule Credo.Check.Refactor.PipeChainStart do
  @moduledoc """
  Checks that each pipe chains start with a "raw" value for better readability.
  """

  @explanation [check: @moduledoc]
  @default_params [excluded_functions: []]

  use Credo.Check

  def run(%SourceFile{ast: ast} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    excluded_functions = params |> Params.get(:excluded_functions, @default_params)


    Credo.Code.prewalk(ast, &traverse(&1, &2, issue_meta, excluded_functions))
  end

  defp traverse({:|>, _, [{:|>, _, _} | _]} = ast, issues, _issue_meta, _excluded_functions) do
    {ast, issues}
  end
  defp traverse({:|>, meta, [lhs | _rhs]} = ast, issues, issue_meta, excluded_functions) do
    if valid_chain_start?(lhs, excluded_functions) do
      {ast, issues}
    else
      {ast, issues ++ [issue_for(issue_meta, meta[:line], "TODO")]}
    end
  end
  defp traverse(ast, issues, _issue_meta, _excluded_functions) do
    {ast, issues}
  end


  for atom <- [:%, :%{}, :.., :<<>>, :@, :__aliases__, :unquote, :{}, :&, :<>, :++, :--] do
    defp valid_chain_start?({unquote(atom), _meta, _arguments}, _excluded_functions) do
      true
    end
  end
  # function_call()
  defp valid_chain_start?({atom, _, []}, _excluded_functions) when is_atom(atom) do
    true
  end
  # function_call(with, args) and sigils
  defp valid_chain_start?({atom, _, arguments} = ast, excluded_functions) when is_atom(atom) and is_list(arguments) do
    function_name = to_function_call_name(ast)
    sigil?(atom) || excluded_functions |> Enum.member?(function_name)
  end
  # map[:access]
  defp valid_chain_start?({{:., _, [Access, :get]}, _, _}, _excluded_functions) do
    true
  end
  # Module.function_call()
  defp valid_chain_start?({{:., _, _}, _, []}, _excluded_functions), do: true
  # Module.function_call(with, parameters)
  defp valid_chain_start?({{:., _, _}, _, _} = ast, excluded_functions) do
    function_name = to_function_call_name(ast)
    excluded_functions |> Enum.member?(function_name)
  end
  defp valid_chain_start?(_, _excluded_functions), do: true

  defp sigil?(atom) do
    atom |> to_string |> String.match?(~r/^sigil_[a-zA-Z]$/)
  end

  defp to_function_call_name({_, _, _} = ast) do
    {ast, [], []}
    |> Macro.to_string()
    |> String.replace(~r/\.?\(.*\)$/s, "")
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue issue_meta,
      message: "Pipe chain should start with a raw value.",
      trigger: trigger,
      line_no: line_no
  end
end
