defmodule Credo.Check.Module do
  @moduledoc false

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
          | :module

  @type location :: [line: pos_integer, column: pos_integer]

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

  defp analyze(state, {clause, meta, _})
       when clause in ~w/use import alias require defstruct/a,
       do: add_module_element(state, clause, meta)

  defp analyze(state, {clause, meta, _})
       when clause in ~w/def defmacro defguard defp defmacrop defguardp/a do
    state
    |> add_module_element(code_type(clause, state.next_fun_modifier), meta)
    |> clear_next_fun_modifier()
  end

  defp analyze(state, {:do, _code}) do
    # Not entering a do block, since this is possibly a custom macro invocation we can't
    # understand.
    state
  end

  defp analyze(state, {:defmodule, meta, _args}),
    do: add_module_element(state, :module, meta)

  defp analyze(_state, _ast), do: nil

  defp code_type(:def, nil), do: :public_fun
  defp code_type(:def, :impl), do: :callback_fun
  defp code_type(:def, :private), do: :private_fun
  defp code_type(:defp, _), do: :private_fun

  defp code_type(:defmacro, nil), do: :public_macro
  defp code_type(:defmacro, :impl), do: :impl
  defp code_type(macro, _) when macro in ~w/defmacro defmacrop/a, do: :private_macro

  defp code_type(:defguard, nil), do: :public_guard
  defp code_type(guard, _) when guard in ~w/defguard defguardp/a, do: :private_guard

  # Internal state

  defp initial_state, do: %{modules: [], current_module: nil, next_fun_modifier: nil}

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
