defmodule Credo.Code.Module do
  @moduledoc """
  This module provides helper functions to analyse modules, return the defined
  functions or module attributes.
  """

  alias Credo.Code.Block
  alias Credo.Code.Name

  @type module_part ::
          :moduledoc
          | :shortdoc
          | :behaviour
          | :use
          | :import
          | :alias
          | :require
          | :module_attribute
          | :defstruct
          | :opaque
          | :type
          | :typep
          | :callback
          | :macrocallback
          | :optional_callbacks
          | :public_fun
          | :private_fun
          | :public_macro
          | :private_macro
          | :public_guard
          | :private_guard
          | :callback_fun
          | :callback_macro
          | :module

  @type location :: [line: pos_integer, column: pos_integer]

  @def_ops [:def, :defp, :defmacro]

  @doc "Returns the list of aliases defined in a given module source code."
  def aliases({:defmodule, _, _arguments} = ast) do
    ast
    |> Credo.Code.postwalk(&find_aliases/2)
    |> Enum.uniq()
  end

  defp find_aliases({:alias, _, [{:__aliases__, _, mod_list}]} = ast, aliases) do
    module_names =
      mod_list
      |> Name.full()
      |> List.wrap()

    {ast, aliases ++ module_names}
  end

  # Multi alias
  defp find_aliases(
         {:alias, _,
          [
            {{:., _, [{:__aliases__, _, mod_list}, :{}]}, _, multi_mod_list}
          ]} = ast,
         aliases
       ) do
    module_names =
      Enum.map(multi_mod_list, fn tuple ->
        Name.full([Name.full(mod_list), Name.full(tuple)])
      end)

    {ast, aliases ++ module_names}
  end

  defp find_aliases(ast, aliases) do
    {ast, aliases}
  end

  @doc "Reads an attribute from a module's `ast`"
  def attribute(ast, attr_name) do
    case Credo.Code.postwalk(ast, &find_attribute(&1, &2, attr_name), {:error, nil}) do
      {:ok, value} ->
        value

      error ->
        error
    end
  end

  defp find_attribute({:@, _meta, arguments} = ast, tuple, attribute_name) do
    case List.first(arguments) do
      {^attribute_name, _meta, [value]} ->
        {:ok, value}

      _ ->
        {ast, tuple}
    end
  end

  defp find_attribute(ast, tuple, _name) do
    {ast, tuple}
  end

  @doc "Returns the function/macro count for the given module's AST"
  def def_count(nil), do: 0

  def def_count({:defmodule, _, _arguments} = ast) do
    ast
    |> Credo.Code.postwalk(&collect_defs/2)
    |> Enum.count()
  end

  def defs(nil), do: []

  def defs({:defmodule, _, _arguments} = ast) do
    Credo.Code.postwalk(ast, &collect_defs/2)
  end

  @doc "Returns the arity of the given function definition `ast`"
  def def_arity(ast)

  for op <- @def_ops do
    def def_arity({unquote(op) = op, _, [{:when, _, fun_ast}, _]}) do
      def_arity({op, nil, fun_ast})
    end

    def def_arity({unquote(op), _, [{_fun_name, _, arguments}, _]})
        when is_list(arguments) do
      Enum.count(arguments)
    end

    def def_arity({unquote(op), _, [{_fun_name, _, _}, _]}), do: 0
  end

  def def_arity(_), do: nil

  @doc "Returns the name of the function/macro defined in the given `ast`"
  for op <- @def_ops do
    def def_name({unquote(op) = op, _, [{:when, _, fun_ast}, _]}) do
      def_name({op, nil, fun_ast})
    end

    def def_name({unquote(op), _, [{fun_name, _, _arguments}, _]})
        when is_atom(fun_name) do
      fun_name
    end
  end

  def def_name(_), do: nil

  @doc "Returns the {fun_name, op} tuple of the function/macro defined in the given `ast`"
  for op <- @def_ops do
    def def_name_with_op({unquote(op) = op, _, _} = ast) do
      {def_name(ast), op}
    end

    def def_name_with_op({unquote(op) = op, _, _} = ast, arity) do
      if def_arity(ast) == arity do
        {def_name(ast), op}
      else
        nil
      end
    end
  end

  def def_name_with_op(_), do: nil

  @doc "Returns the name of the functions/macros for the given module's `ast`"
  def def_names(nil), do: []

  def def_names({:defmodule, _, _arguments} = ast) do
    ast
    |> Credo.Code.postwalk(&collect_defs/2)
    |> Enum.map(&def_name/1)
    |> Enum.uniq()
  end

  @doc "Returns the name of the functions/macros for the given module's `ast`"
  def def_names_with_op(nil), do: []

  def def_names_with_op({:defmodule, _, _arguments} = ast) do
    ast
    |> Credo.Code.postwalk(&collect_defs/2)
    |> Enum.map(&def_name_with_op/1)
    |> Enum.uniq()
  end

  @doc "Returns the name of the functions/macros for the given module's `ast` if it has the given `arity`."
  def def_names_with_op(nil, _arity), do: []

  def def_names_with_op({:defmodule, _, _arguments} = ast, arity) do
    ast
    |> Credo.Code.postwalk(&collect_defs/2)
    |> Enum.map(&def_name_with_op(&1, arity))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  for op <- @def_ops do
    defp collect_defs({:@, _, [{unquote(op), _, arguments} = ast]}, defs)
         when is_list(arguments) do
      {ast, defs -- [ast]}
    end

    defp collect_defs({unquote(op), _, arguments} = ast, defs)
         when is_list(arguments) do
      {ast, defs ++ [ast]}
    end
  end

  defp collect_defs(ast, defs) do
    {ast, defs}
  end

  @doc "Returns the list of modules used in a given module source code."
  def modules({:defmodule, _, _arguments} = ast) do
    ast
    |> Credo.Code.postwalk(&find_dependent_modules/2)
    |> Enum.uniq()
  end

  # exclude module name
  defp find_dependent_modules(
         {:defmodule, _, [{:__aliases__, _, mod_list}, _do_block]} = ast,
         modules
       ) do
    module_names =
      mod_list
      |> Name.full()
      |> List.wrap()

    {ast, modules -- module_names}
  end

  # single alias
  defp find_dependent_modules(
         {:alias, _, [{:__aliases__, _, mod_list}]} = ast,
         aliases
       ) do
    module_names =
      mod_list
      |> Name.full()
      |> List.wrap()

    {ast, aliases -- module_names}
  end

  # multi alias
  defp find_dependent_modules(
         {:alias, _,
          [
            {{:., _, [{:__aliases__, _, mod_list}, :{}]}, _, multi_mod_list}
          ]} = ast,
         modules
       ) do
    module_names =
      Enum.flat_map(multi_mod_list, fn tuple ->
        [Name.full(mod_list), Name.full(tuple)]
      end)

    {ast, modules -- module_names}
  end

  defp find_dependent_modules({:__aliases__, _, mod_list} = ast, modules) do
    module_names =
      mod_list
      |> Name.full()
      |> List.wrap()

    {ast, modules ++ module_names}
  end

  defp find_dependent_modules(ast, modules) do
    {ast, modules}
  end

  @doc """
  Returns the name of a module's given ast node.
  """
  def name(ast)

  def name({:defmodule, _, [{:__aliases__, _, name_list}, _]}) do
    Enum.map_join(name_list, ".", &name/1)
  end

  def name({:__MODULE__, _meta, nil}), do: "__MODULE__"

  def name(atom) when is_atom(atom), do: atom |> to_string |> String.replace(~r/^Elixir\./, "")

  def name(string) when is_binary(string), do: string

  def name(_), do: "<Unknown Module Name>"

  # TODO: write unit test
  def exception?({:defmodule, _, [{:__aliases__, _, _name_list}, arguments]}) do
    arguments
    |> Block.calls_in_do_block()
    |> Enum.any?(&defexception?/1)
  end

  def exception?(_), do: nil

  defp defexception?({:defexception, _, _}), do: true
  defp defexception?(_), do: false

  @spec analyze(Macro.t()) :: [{module, [{module_part, location}]}]
  def analyze(ast) do
    {_ast, state} = Macro.prewalk(ast, initial_state(), &traverse_file/2)
    module_parts(state)
  end

  defp traverse_file({:defmodule, meta, args}, state) do
    [first_arg, [do: module_ast]] = args

    state = start_module(state, meta)
    {_ast, state} = Macro.prewalk(module_ast, state, &traverse_module/2)

    module_name = module_name(first_arg)
    this_module = {module_name, state.current_module}
    submodules = find_inner_modules(module_name, module_ast)

    state = update_in(state.modules, &(&1 ++ [this_module | submodules]))
    {[], state}
  end

  defp traverse_file(ast, state), do: {ast, state}

  defp module_name({:__aliases__, _, name_parts}) do
    name_parts
    |> Enum.map(fn
      atom when is_atom(atom) -> atom
      _other -> Unknown
    end)
    |> Module.concat()
  end

  defp module_name(_other), do: Unknown

  defp find_inner_modules(module_name, module_ast) do
    {_ast, definitions} = Macro.prewalk(module_ast, initial_state(), &traverse_file/2)

    Enum.map(
      definitions.modules,
      fn {submodule_name, submodule_spec} ->
        {Module.concat(module_name, submodule_name), submodule_spec}
      end
    )
  end

  defp traverse_module(ast, state) do
    case analyze(state, ast) do
      nil -> traverse_deeper(ast, state)
      state -> traverse_sibling(state)
    end
  end

  defp traverse_deeper(ast, state), do: {ast, state}
  defp traverse_sibling(state), do: {[], state}

  # Part extractors

  defp analyze(state, {:@, _meta, [{:doc, _, [value]}]}),
    do: set_next_fun_modifier(state, if(value == false, do: :private, else: nil))

  defp analyze(state, {:@, _meta, [{:impl, _, [value]}]}),
    do: set_next_fun_modifier(state, if(value == false, do: nil, else: :impl))

  defp analyze(state, {:@, meta, [{attribute, _, _}]})
       when attribute in ~w/moduledoc shortdoc behaviour type typep opaque callback macrocallback optional_callbacks/a,
       do: add_module_element(state, attribute, meta)

  defp analyze(state, {:@, _meta, [{ignore_attribute, _, _}]})
       when ignore_attribute in ~w/after_compile before_compile compile impl deprecated doc
       typedoc dialyzer external_resource file on_definition on_load vsn spec/a,
       do: state

  defp analyze(state, {:@, meta, _}),
    do: add_module_element(state, :module_attribute, meta)

  defp analyze(state, {clause, meta, args})
       when clause in ~w/use import alias require defstruct/a and is_list(args),
       do: add_module_element(state, clause, meta)

  defp analyze(state, {clause, meta, definition})
       when clause in ~w/def defmacro defguard defp defmacrop defguardp/a do
    fun_name = fun_name(definition)

    if fun_name != state.last_fun_name do
      state
      |> add_module_element(code_type(clause, state.next_fun_modifier), meta)
      |> Map.put(:last_fun_name, fun_name)
      |> clear_next_fun_modifier()
    else
      state
    end
  end

  defp analyze(state, {:do, _code}) do
    # Not entering a do block, since this is possibly a custom macro invocation we can't
    # understand.
    state
  end

  defp analyze(state, {:defmodule, meta, _args}),
    do: add_module_element(state, :module, meta)

  defp analyze(_state, _ast), do: nil

  defp fun_name([{name, _context, arity} | _]) when is_list(arity), do: {name, length(arity)}
  defp fun_name([{name, _context, _} | _]), do: {name, 0}
  defp fun_name(_), do: nil

  defp code_type(:def, nil), do: :public_fun
  defp code_type(:def, :impl), do: :callback_fun
  defp code_type(:def, :private), do: :private_fun
  defp code_type(:defp, _), do: :private_fun

  defp code_type(:defmacro, nil), do: :public_macro
  defp code_type(:defmacro, :impl), do: :callback_macro
  defp code_type(macro, _) when macro in ~w/defmacro defmacrop/a, do: :private_macro

  defp code_type(:defguard, nil), do: :public_guard
  defp code_type(guard, _) when guard in ~w/defguard defguardp/a, do: :private_guard

  # Internal state

  defp initial_state,
    do: %{modules: [], current_module: nil, next_fun_modifier: nil, last_fun_name: nil}

  defp set_next_fun_modifier(state, value), do: %{state | next_fun_modifier: value}

  defp clear_next_fun_modifier(state), do: set_next_fun_modifier(state, nil)

  defp module_parts(state) do
    state.modules
    |> Enum.sort_by(fn {_name, module} -> module.location end)
    |> Enum.map(fn {name, module} -> {name, Enum.reverse(module.parts)} end)
  end

  defp start_module(state, meta) do
    %{state | current_module: %{parts: [], location: Keyword.take(meta, ~w/line column/a)}}
  end

  defp add_module_element(state, element, meta) do
    location = Keyword.take(meta, ~w/line column/a)
    update_in(state.current_module.parts, &[{element, location} | &1])
  end
end
