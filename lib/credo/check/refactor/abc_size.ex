defmodule Credo.Check.Refactor.ABCSize do
  @moduledoc """
  The ABC size describes a metric based on assignments, branches and conditions.

  A high ABC size is a hint that a function might be doing "more" than it
  should.

  As always: Take any metric with a grain of salt. Since this one was originally
  introduced for C, C++ and Java, we still have to see whether or not this can
  be a useful metric in a declarative language like Elixir.
  """

  @explanation [
    check: @moduledoc,
    params: [
      max_size: "The maximum ABC size a function should have.",
    ]
  ]
  @default_params [
    max_size: 30
  ]
  @def_ops [:def, :defp, :defmacro]
  @branch_ops [:.]
  @condition_ops [:if, :unless, :for, :try, :case, :cond, :and, :or, :&&, :||]

  alias Credo.SourceFile
  alias Credo.Check.CodeHelper

  use Credo.Check

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    max_abc_size = Params.get(params, :max_size, @default_params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta, max_abc_size))
  end

  defp traverse({:defmacro, _, [{:__using__, _, _}, _]} = ast, issues, _, _) do
    {ast, issues}
  end
  for op <- @def_ops do
    defp traverse({unquote(op), meta, arguments} = ast, issues, issue_meta, max_abc_size) when is_list(arguments) do
      abc_size =
        ast
        |> abc_size_for
        |> round

      if abc_size > max_abc_size do
        fun_name = CodeHelper.def_name(ast)

        {ast, [issue_for(issue_meta, meta[:line], fun_name, max_abc_size, abc_size) | issues]}
      else
        {ast, issues}
      end
    end
  end
  defp traverse(ast, issues, _issue_meta, _max_abc_size) do
    {ast, issues}
  end

  @doc """
  Returns the ABC size for the block inside the given AST, which is expected
  to represent a function or macro definition.

      iex> {:def, [line: 1],
      ...>   [
      ...>     {:first_fun, [line: 1], nil},
      ...>     [do: {:=, [line: 2], [{:x, [line: 2], nil}, 1]}]
      ...>   ]
      ...> } |> Credo.Check.Refactor.ABCSize.abc_size
      1.0
  """
  def abc_size_for({_def_op, _meta, arguments}) when is_list(arguments) do
    arguments
    |> CodeHelper.do_block_for!
    |> abc_size_for(arguments)
  end

  @doc false
  def abc_size_for(nil, _arguments), do: 0
  def abc_size_for(ast, arguments) do
    initial_acc = [a: 0, b: 0, c: 0, var_names: get_parameters(arguments)]

    [a: a, b: b, c: c, var_names: _] = Credo.Code.prewalk(ast, &traverse_abc/2,
                                              initial_acc)

    :math.sqrt(a * a + b * b + c * c)
  end

  def get_parameters(arguments) do
    case Enum.at(arguments, 0) do
      {_name, _meta, nil} ->
        []
      {_name, _meta, parameters} ->
        Enum.map(parameters, &var_name/1)
    end
  end

  for op <- @def_ops do
    defp traverse_abc({unquote(op), _, arguments} = ast, abc) when is_list(arguments) do
      {ast, abc}
    end
  end

  # Ignore string interpolation
  defp traverse_abc({:<<>>, _, _}, acc) do
    {nil, acc}
  end

  # A - assignments
  defp traverse_abc({:=, _meta, [lhs | rhs]}, [a: a, b: b, c: c, var_names: var_names]) do
    var_names =
      case var_name(lhs) do
        nil ->
          var_names
        false ->
          var_names
        name ->
          Enum.into var_names, [name]
      end
    {rhs, [a: a + 1, b: b, c: c, var_names: var_names]}
  end

  # B - branch
  defp traverse_abc({:->, _meta, arguments} = ast, [a: a, b: b, c: c, var_names: var_names]) do
    var_names = Enum.into var_names, fn_parameters(arguments)
    {ast, [a: a, b: b + 1, c: c, var_names: var_names]}
  end
  for op <- @branch_ops do
    defp traverse_abc({unquote(op), _meta, [{_, _, nil}, _] = arguments} = ast, [a: a, b: b, c: c, var_names: var_names]) when is_list(arguments) do
      {ast, [a: a, b: b, c: c, var_names: var_names]}
    end
    defp traverse_abc({unquote(op), _meta, arguments} = ast, [a: a, b: b, c: c, var_names: var_names]) when is_list(arguments) do
      {ast, [a: a, b: b + 1, c: c, var_names: var_names]}
    end
  end
  defp traverse_abc({fun_or_var_name, _meta, nil} = ast, [a: a, b: b, c: c, var_names: var_names]) do
    is_variable = Enum.member?(var_names, fun_or_var_name)

    if is_variable do
      {ast, [a: a, b: b, c: c, var_names: var_names]}
    else
      {ast, [a: a, b: b + 1, c: c, var_names: var_names]}
    end
  end

  # C - conditions
  for op <- @condition_ops do
    defp traverse_abc({unquote(op), _meta, arguments} = ast, [a: a, b: b, c: c, var_names: var_names]) when is_list(arguments) do
      {ast, [a: a, b: b, c: c + 1, var_names: var_names]}
    end
  end

  defp traverse_abc(ast, abc) do
    {ast, abc}
  end

  defp var_name({name, _, nil}) when is_atom(name), do: name
  defp var_name(_), do: nil

  def fn_parameters([params, tuple]) when is_list(params) and is_tuple(tuple) do
    fn_parameters(params)
  end
  def fn_parameters([[{:when, _, params}], _]) when is_list(params) do
    fn_parameters(params)
  end
  def fn_parameters(params) when is_list(params) do
    params
    |> Enum.map(&var_name/1)
    |> Enum.reject(&is_nil/1)
  end


  def issue_for(issue_meta, line_no, trigger, max_value, actual_value) do
    format_issue issue_meta,
      message: "Function is too complex (ABC size is #{actual_value}, max is #{max_value}).",
      trigger: trigger,
      line_no: line_no,
      severity: Severity.compute(actual_value, max_value)
  end
end
