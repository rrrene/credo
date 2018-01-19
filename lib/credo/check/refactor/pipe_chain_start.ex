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
    excluded_functions: "All functions listed will be ignored."
  ]
  @default_params [excluded_functions: []]

  use Credo.Check

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    excluded_functions =
      Params.get(params, :excluded_functions, @default_params)

    Credo.Code.prewalk(
      source_file,
      &traverse(&1, &2, issue_meta, excluded_functions)
    )
  end

  defp traverse(
         {:|>, _, [{:|>, _, _} | _]} = ast,
         issues,
         _issue_meta,
         _excluded_functions
       ) do
    {ast, issues}
  end

  defp traverse(
         {:|>, meta, [lhs | _rhs]} = ast,
         issues,
         issue_meta,
         excluded_functions
       ) do
    if valid_chain_start?(lhs, excluded_functions) do
      {ast, issues}
    else
      {ast, issues ++ [issue_for(issue_meta, meta[:line], "TODO")]}
    end
  end

  defp traverse(ast, issues, _issue_meta, _excluded_functions) do
    {ast, issues}
  end

  for atom <- [
        :%,
        :%{},
        :..,
        :<<>>,
        :@,
        :__aliases__,
        :unquote,
        :{},
        :&,
        :<>,
        :++,
        :--,
        :&&,
        :||,
        :-,
        :for,
        :with,
        :<-
      ] do
    defp valid_chain_start?(
           {unquote(atom), _meta, _arguments},
           _excluded_functions
         ) do
      true
    end
  end

  # anonymous function
  defp valid_chain_start?(
         {:fn, _, [{:->, _, [_args, _body]}]},
         _excluded_functions
       ) do
    true
  end

  # function_call()
  defp valid_chain_start?({atom, _, []}, _excluded_functions) when is_atom(atom) do
    true
  end

  # function_call(with, args) and sigils
  defp valid_chain_start?({atom, _, arguments} = ast, excluded_functions)
       when is_atom(atom) and is_list(arguments) do
    sigil?(atom) || valid_chain_start_function_call?(ast, excluded_functions)
  end

  # map[:access]
  defp valid_chain_start?({{:., _, [Access, :get]}, _, _}, _excluded_functions) do
    true
  end

  # Module.function_call()
  defp valid_chain_start?({{:., _, _}, _, []}, _excluded_functions), do: true
  # Module.function_call(with, parameters)
  defp valid_chain_start?({{:., _, _}, _, _} = ast, excluded_functions) do
    valid_chain_start_function_call?(ast, excluded_functions)
  end

  defp valid_chain_start?(_, _excluded_functions), do: true

  defp valid_chain_start_function_call?(
         {_atom, _, arguments} = ast,
         excluded_functions
       ) do
    function_name = to_function_call_name(ast)

    IO.inspect(ast, label: "lhs")

    Enum.member?(excluded_functions, function_name)
  end

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

  defp parameter_types(list) do
    Enum.map(&parameter_type/1)
  end

  defp parameter_types(v) when is_atom(v), do: :atom
  defp parameter_types(v) when is_binary(v), do: :binary
  defp parameter_types(v) when is_bitstring(v), do: :bitstring
  defp parameter_types(v) when is_boolean(v), do: :boolean
  defp parameter_types(v) when is_list(v), do: :list
  defp parameter_types(v) when is_number(v), do: :number
  defp parameter_types({:%{}, _, _}), do: :map
  defp parameter_types({:{}, _, _}), do: :tuple
  defp parameter_types(nil), do: nil
  defp parameter_types(_), do: :credo_error

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message: "Pipe chain should start with a raw value.",
      trigger: trigger,
      line_no: line_no
    )
  end
end
