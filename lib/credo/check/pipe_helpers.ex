defmodule Credo.Check.PipeHelpers do
  @elixir_custom_operators [
    :<-,
    :|||,
    :&&&,
    :<<<,
    :>>>,
    :<<~,
    :~>>,
    :<~,
    :~>,
    :<~>,
    :"<|>",
    :"^^^",
    :"~~~",
    :"..//"
  ]

  def valid_chain_start?(
         {:__block__, _, [single_ast_node]},
         excluded_functions,
         excluded_argument_types
       ) do
    valid_chain_start?(
      single_ast_node,
      excluded_functions,
      excluded_argument_types
    )
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
        :+,
        :-,
        :*,
        :/,
        :>,
        :>=,
        :<,
        :<=,
        :==,
        :for,
        :with,
        :not,
        :and,
        :or
      ] do
    def valid_chain_start?(
           {unquote(atom), _meta, _arguments},
           _excluded_functions,
           _excluded_argument_types
         ) do
      true
    end
  end

  for operator <- @elixir_custom_operators do
    def valid_chain_start?(
           {unquote(operator), _meta, _arguments},
           _excluded_functions,
           _excluded_argument_types
         ) do
      true
    end
  end

  # anonymous function
  def valid_chain_start?(
         {:fn, _, [{:->, _, [_args, _body]}]},
         _excluded_functions,
         _excluded_argument_types
       ) do
    true
  end

  # function_call()
  def valid_chain_start?(
         {atom, _, []},
         _excluded_functions,
         _excluded_argument_types
       )
       when is_atom(atom) do
    true
  end

  # function_call(with, args) and sigils
  def valid_chain_start?(
         {atom, _, arguments} = ast,
         excluded_functions,
         excluded_argument_types
       )
       when is_atom(atom) and is_list(arguments) do
    sigil?(atom) ||
      valid_chain_start_function_call?(
        ast,
        excluded_functions,
        excluded_argument_types
      )
  end

  # map[:access]
  def valid_chain_start?(
         {{:., _, [Access, :get]}, _, _},
         _excluded_functions,
         _excluded_argument_types
       ) do
    true
  end

  # Module.function_call()
  def valid_chain_start?(
         {{:., _, _}, _, []},
         _excluded_functions,
         _excluded_argument_types
       ),
       do: true

  # Elixir <= 1.8.0
  # '__#{val}__' are compiled to String.to_charlist("__#{val}__")
  # we want to consider these charlists a valid pipe chain start
  def valid_chain_start?(
         {{:., _, [String, :to_charlist]}, _, [{:<<>>, _, _}]},
         _excluded_functions,
         _excluded_argument_types
       ),
       do: true

  # Elixir >= 1.8.0
  # '__#{val}__' are compiled to String.to_charlist("__#{val}__")
  # we want to consider these charlists a valid pipe chain start
  def valid_chain_start?(
         {{:., _, [List, :to_charlist]}, _, [[_ | _]]},
         _excluded_functions,
         _excluded_argument_types
       ),
       do: true

  # Module.function_call(with, parameters)
  def valid_chain_start?(
         {{:., _, _}, _, _} = ast,
         excluded_functions,
         excluded_argument_types
       ) do
    valid_chain_start_function_call?(
      ast,
      excluded_functions,
      excluded_argument_types
    )
  end

  def valid_chain_start?(_, _excluded_functions, _excluded_argument_types), do: true

  def valid_chain_start_function_call?(
         {_atom, _, arguments} = ast,
         excluded_functions,
         excluded_argument_types
       ) do
    function_name = to_function_call_name(ast)

    found_argument_types =
      case arguments do
        [nil | _] -> [:atom]
        x -> x |> List.first() |> argument_type()
      end

    Enum.member?(excluded_functions, function_name) ||
      Enum.any?(
        found_argument_types,
        &Enum.member?(excluded_argument_types, &1)
      )
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

  @alphabet_wo_r ~w(a b c d e f g h i j k l m n o p q s t u v w x y z)
  @all_sigil_chars Enum.flat_map(@alphabet_wo_r, &[&1, String.upcase(&1)])
  @matchable_sigils Enum.map(@all_sigil_chars, &:"sigil_#{&1}")

  for sigil_atom <- @matchable_sigils do
    defp argument_type({unquote(sigil_atom), _, _}) do
      [unquote(sigil_atom)]
    end
  end

  defp argument_type({:sigil_r, _, _}), do: [:sigil_r, :regex]
  defp argument_type({:sigil_R, _, _}), do: [:sigil_R, :regex]

  defp argument_type({:fn, _, _}), do: [:fn]
  defp argument_type({:%{}, _, _}), do: [:map]
  defp argument_type({:{}, _, _}), do: [:tuple]
  defp argument_type(nil), do: []

  defp argument_type(v) when is_atom(v), do: [:atom]
  defp argument_type(v) when is_binary(v), do: [:binary]
  defp argument_type(v) when is_bitstring(v), do: [:bitstring]
  defp argument_type(v) when is_boolean(v), do: [:boolean]

  defp argument_type(v) when is_list(v) do
    if Keyword.keyword?(v) do
      [:keyword, :list]
    else
      [:list]
    end
  end

  defp argument_type(v) when is_number(v), do: [:number]

  defp argument_type(v), do: [:credo_type_error, v]
end
