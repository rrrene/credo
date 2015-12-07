defmodule Credo.Check.Refactor.PipeChainStart do
  @moduledoc """
  Checks that each pipe chains start with a "raw" value for better readability.
  """

  @explanation [check: @moduledoc]

  use Credo.Check

  def run(%SourceFile{ast: ast} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.traverse(ast, &traverse(&1, &2, issue_meta))
  end

  defp traverse({:|>, _, [{:|>, _, _} | _]} = ast, issues, _issue_meta) do
    {ast, issues}
  end
  defp traverse({:|>, meta, [lhs | _rhs]} = ast, issues, issue_meta) do
    if valid_chain_start?(lhs) do
      {ast, issues}
    else
      {ast, issues ++ [issue_for(meta[:line], "TODO", issue_meta)]}
    end
  end
  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end


  for atom <- [:%, :%{}, :.., :<<>>, :@, :__aliases__, :unquote, :{}] do
    defp valid_chain_start?({unquote(atom), _meta, _arguments}) do
      true
    end
  end
  defp valid_chain_start?({atom, _, arguments}) when is_atom(atom) and is_list(arguments) do
    atom |> to_string |> String.match?(~r/^sigil_[a-zA-Z]$/)
  end
  defp valid_chain_start?({{:., _, [Access, :get]}, _, _}) do
    true
  end
  defp valid_chain_start?({{:., _, _}, _, []}), do: true
  defp valid_chain_start?({{:., _, _}, _, _}), do: false
  defp valid_chain_start?(_), do: true

  defp issue_for(line_no, trigger, issue_meta) do
    format_issue issue_meta,
      message: "Pipe chain should start with a raw value.",
      trigger: trigger,
      line_no: line_no
  end
end
