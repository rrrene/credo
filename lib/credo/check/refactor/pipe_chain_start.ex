defmodule Credo.Check.Refactor.PipeChainStart do
  @moduledoc """
  Pipes (`|>`) can become more readable by starting with a "raw" value.

  So while this is easily comprehendable:

      list
      |> Enum.take(5)
      |> Enum.shuffle
      |> pick_winner()

  This might be harder to read:

      Enum.take(list, 5)
      |> Enum.shuffle
      |> pick_winner()

  As always: This is just a suggestion. Check the configuration options for
  tweaking or disabling this check.
  """

  @explanation [
    check: @moduledoc,
    excluded_functions: "All functions listed will be ignored.",
    exclude_erlang_funcs: "Specifies that we want to treat erlang functions as raw values"
  ]
  @default_params [excluded_functions: [], exclude_erlang_funcs: false]

  use Credo.Check

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    excluded_functions = Params.get(params, :excluded_functions, @default_params)
    exclude_erlang_funcs = Params.get(params, :exclude_erlang_funcs, @default_params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta, excluded_functions, exclude_erlang_funcs))
  end

  defp traverse({:|>, _, [{:|>, _, _} | _]} = ast, issues, _issue_meta, _excluded_functions, _exclude_erlang_funcs) do
    {ast, issues}
  end
  defp traverse({:|>, meta, [lhs | _rhs]} = ast, issues, issue_meta, excluded_functions, exclude_erlang_funcs) do
    if valid_chain_start?(lhs, excluded_functions, exclude_erlang_funcs) do
      {ast, issues}
    else
      {ast, issues ++ [issue_for(issue_meta, meta[:line], "TODO")]}
    end
  end
  defp traverse(ast, issues, _issue_meta, _excluded_functions, _exclude_erlang_funcs) do
    {ast, issues}
  end


  for atom <- [:%, :%{}, :.., :<<>>, :@, :__aliases__, :unquote, :{}, :&, :<>, :++, :--, :&&, :||, :-, :for, :with, :<-] do
    defp valid_chain_start?({unquote(atom), _meta, _arguments}, _excluded_functions, _exclude_erlang_funcs) do
      true
    end
  end
  # anonymous function
  defp valid_chain_start?({:fn, _, [{:->, _, [_args, _body]}]}, _excluded_functions, _exclude_erlang_funcs) do
    true
  end
  # function_call()
  defp valid_chain_start?({atom, _, []}, _excluded_functions, _exclude_erlang_funcs) when is_atom(atom) do
    true
  end
  # function_call(with, args) and sigils
  defp valid_chain_start?({atom, _, arguments} = ast, excluded_functions, _exclude_erlang_funcs) when is_atom(atom) and is_list(arguments) do
    function_name = to_function_call_name(ast)

    sigil?(atom) || Enum.member?(excluded_functions, function_name)
  end
  # map[:access]
  defp valid_chain_start?({{:., _, [Access, :get]}, _, _}, _excluded_functions, _exclude_erlang_funcs) do
    true
  end
  # Module.function_call()
  defp valid_chain_start?({{:., _, _}, _, []}, _excluded_functions, _exclude_erlang_funcs), do: true
  defp valid_chain_start?({{:., _, [module_name, _]}, _, _} = ast, excluded_functions, exclude_erlang_funcs) when is_atom(module_name) do
    function_name = to_function_call_name(ast)

    try do
      module_name.module_info # ensure erlang module is loaded
      :erlang.get_module_info(module_name, :module) # check if module is a erlang one

      # Is a Erlang lib
      exclude_erlang_funcs || Enum.member?(excluded_functions, function_name)
    rescue
      # Not a Erlang lib
      [UndefinedFunctionError, ArgumentError] -> Enum.member?(excluded_functions, function_name)
    end
  end
  # Module.function_call(with, parameters)
  defp valid_chain_start?({{:., _, _}, _, _} = ast, excluded_functions, _exclude_erlang_funcs) do
    function_name = to_function_call_name(ast)

    Enum.member?(excluded_functions, function_name)
  end
  defp valid_chain_start?(_, _excluded_functions, _exclude_erlang_funcs), do: true

  defp sigil?(atom) do
    atom
    |> to_string
    |> String.match?(~r/^sigil_[a-zA-Z]$/)
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
