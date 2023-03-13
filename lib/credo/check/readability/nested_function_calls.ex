defmodule Credo.Check.Readability.NestedFunctionCalls do
  use Credo.Check,
    id: "EX3012",
    tags: [:controversial],
    param_defaults: [min_pipeline_length: 2],
    explanations: [
      check: """
      A function call should not be nested inside another function call.

      So while this is fine:

          Enum.shuffle([1,2,3])

      The code in this example ...

          Enum.shuffle(Enum.uniq([1,2,3,3]))

      ... should be refactored to look like this:

          [1,2,3,3]
          |> Enum.uniq()
          |> Enum.shuffle()

      Nested function calls make the code harder to read. Instead, break the
      function calls out into a pipeline.

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """,
      params: [
        min_pipeline_length: "Set a minimum pipeline length"
      ]
    ]

  alias Credo.Check.Readability.NestedFunctionCalls.PipeHelper
  alias Credo.Code.Name

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    min_pipeline_length = Params.get(params, :min_pipeline_length, __MODULE__)

    {_min_pipeline_length, issues} =
      Credo.Code.prewalk(
        source_file,
        &traverse(&1, &2, issue_meta),
        {min_pipeline_length, []}
      )

    issues
  end

  # A call in a pipeline
  defp traverse({:|>, _meta, [pipe_input, {{:., _meta2, _fun}, _meta3, args}]}, acc, _issue) do
    {[pipe_input, args], acc}
  end

  # A fully qualified call with no arguments
  defp traverse({{:., _meta, _call}, _meta2, []} = ast, accumulator, _issue) do
    {ast, accumulator}
  end

  # Any call
  defp traverse(
         {{_name, _loc, call}, meta, args} = ast,
         {min_pipeline_length, issues} = acc,
         issue_meta
       ) do
    if cannot_be_in_pipeline?(ast) do
      {ast, acc}
    else
      case length_as_pipeline(args) + 1 do
        potential_pipeline_length when potential_pipeline_length >= min_pipeline_length ->
          new_issues = issues ++ [issue_for(issue_meta, meta[:line], Name.full(call))]
          {ast, {min_pipeline_length, new_issues}}

        _ ->
          {nil, acc}
      end
    end
  end

  # Another expression, we must no longer be in a pipeline
  defp traverse(ast, {min_pipeline_length, issues}, _issue_meta) do
    {ast, {min_pipeline_length, issues}}
  end

  # Call with function call for first argument
  defp length_as_pipeline([{_name, _meta, args} = call_ast | _]) do
    if cannot_be_in_pipeline?(call_ast) do
      0
    else
      1 + length_as_pipeline(args)
    end
  end

  # Call where the first argument isn't another function call
  defp length_as_pipeline(_args) do
    0
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message: "Use a pipeline when there are nested function calls",
      trigger: trigger,
      line_no: line_no
    )
  end

  defp cannot_be_in_pipeline?(ast) do
    PipeHelper.cannot_be_in_pipeline?(ast, [], [])
  end

  defmodule PipeHelper do
    @moduledoc """
    This module exists to contain logic for the cannot_be_in_pipline?/3 helper
    function. This function was originally copied from the
    Credo.Check.Refactor.PipeChainStart module's valid_chain_start?/3 function.
    Both functions are identical.
    """

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

    def cannot_be_in_pipeline?(
          {:__block__, _, [single_ast_node]},
          excluded_functions,
          excluded_argument_types
        ) do
      cannot_be_in_pipeline?(
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
      def cannot_be_in_pipeline?(
            {unquote(atom), _meta, _arguments},
            _excluded_functions,
            _excluded_argument_types
          ) do
        true
      end
    end

    for operator <- @elixir_custom_operators do
      def cannot_be_in_pipeline?(
            {unquote(operator), _meta, _arguments},
            _excluded_functions,
            _excluded_argument_types
          ) do
        true
      end
    end

    # anonymous function
    def cannot_be_in_pipeline?(
          {:fn, _, [{:->, _, [_args, _body]}]},
          _excluded_functions,
          _excluded_argument_types
        ) do
      true
    end

    # function_call()
    def cannot_be_in_pipeline?(
          {atom, _, []},
          _excluded_functions,
          _excluded_argument_types
        )
        when is_atom(atom) do
      true
    end

    # function_call(with, args) and sigils
    def cannot_be_in_pipeline?(
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
    def cannot_be_in_pipeline?(
          {{:., _, [Access, :get]}, _, _},
          _excluded_functions,
          _excluded_argument_types
        ) do
      true
    end

    # Module.function_call()
    def cannot_be_in_pipeline?(
          {{:., _, _}, _, []},
          _excluded_functions,
          _excluded_argument_types
        ),
        do: true

    # Elixir <= 1.8.0
    # '__#{val}__' are compiled to String.to_charlist("__#{val}__")
    # we want to consider these charlists a valid pipe chain start
    def cannot_be_in_pipeline?(
          {{:., _, [String, :to_charlist]}, _, [{:<<>>, _, _}]},
          _excluded_functions,
          _excluded_argument_types
        ),
        do: true

    # Elixir >= 1.8.0
    # '__#{val}__' are compiled to String.to_charlist("__#{val}__")
    # we want to consider these charlists a valid pipe chain start
    def cannot_be_in_pipeline?(
          {{:., _, [List, :to_charlist]}, _, [[_ | _]]},
          _excluded_functions,
          _excluded_argument_types
        ),
        do: true

    # Module.function_call(with, parameters)
    def cannot_be_in_pipeline?(
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

    def cannot_be_in_pipeline?(_, _excluded_functions, _excluded_argument_types), do: true

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
end
