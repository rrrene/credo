defmodule Credo.Check.Refactor.PerceivedComplexity do
  @moduledoc """
  Cyclomatic complexity is a software complexity metric closely correlated with
  coding errors.

  If a function feels like it's gotten too complex, it more often than not also
  has a high CC value. So, if anything, this is useful to convince team members
  and bosses of a need to refactor parts of the code based on "objective"
  metrics.
  """

  @explanation [
    check: @moduledoc,
    params: [
      max_complexity: "The maximum cyclomatic complexity a function should have."
    ]
  ]
  @default_params [max_complexity: 9]

  @def_ops [:def, :defp, :defmacro]
  # these have two outcomes: it succeeds or does not
  @double_condition_ops [:if, :unless, :for, :try, :and, :or, :&&, :||]
  # these can have multiple outcomes as they are defined in their do blocks
  @multiple_condition_ops [:case, :cond]
  @op_complexity_map [
    def: 1,
    defp: 1,
    defmacro: 1,
    if: 1,
    unless: 1,
    for: 1,
    try: 1,
    and: 1,
    or: 1,
    &&: 1,
    ||: 1,
    case: 0.3,
    cond: 1,
  ]


  alias Credo.Check.CodeHelper
  alias Credo.SourceFile

  use Credo.Check

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    max_complexity = Params.get(params, :max_complexity, @default_params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta, max_complexity))
  end

  # exception for `__using__` macros
  defp traverse({:defmacro, _, [{:__using__, _, _}, _]} = ast, issues, _, _) do
    {ast, issues}
  end
  for op <- @def_ops do
    defp traverse({unquote(op), meta, arguments} = ast, issues, issue_meta, max_complexity) when is_list(arguments) do
      complexity =
        ast
        |> complexity_for
        |> round

      if complexity > max_complexity do
        fun_name = CodeHelper.def_name(ast)

        {ast, issues ++ [issue_for(issue_meta, meta[:line], fun_name, max_complexity, complexity)]}
      else
        {ast, issues}
      end
    end
  end
  defp traverse(ast, issues, _source_file, _max_complexity) do
    {ast, issues}
  end

  @doc """
  Returns the Cyclomatic Complexity score for the block inside the given AST,
  which is expected to represent a function or macro definition.

      iex> {:def, [line: 1],
      ...>   [
      ...>     {:first_fun, [line: 1], nil},
      ...>     [do: {:=, [line: 2], [{:x, [line: 2], nil}, 1]}]
      ...>   ]
      ...> } |> Credo.Check.Refactor.CyclomaticComplexity.complexity_for
      1.0
  """
  def complexity_for({_def_op, _meta, _arguments} = ast) do
    Credo.Code.prewalk(ast, &traverse_complexity/2, 0)
  end

  for op <- @def_ops do
    defp traverse_complexity({unquote(op) = op, _meta, arguments} = ast, complexity) when is_list(arguments) do
      {ast, complexity + @op_complexity_map[op]}
    end
  end

  for op <- @double_condition_ops do
    defp traverse_complexity({unquote(op) = op, _meta, arguments} = ast, complexity) when is_list(arguments) do
      {ast, complexity + @op_complexity_map[op]}
    end
  end

  for op <- @multiple_condition_ops do
    defp traverse_complexity({unquote(op), _meta, nil} = ast, complexity) do
      {ast, complexity}
    end
    defp traverse_complexity({unquote(op) = op, _meta, arguments} = ast, complexity) when is_list(arguments) do
      block_cc =
        arguments
        |> CodeHelper.do_block_for!
        |> do_block_complexity(op)

      {ast, complexity + block_cc}
    end
  end
  defp traverse_complexity(ast, complexity) do
    {ast, complexity}
  end

  defp do_block_complexity(nil, _), do: 0
  defp do_block_complexity(block, op) do
    count =
      block
      |> List.wrap
      |> Enum.count

    count * @op_complexity_map[op]
  end

  def issue_for(issue_meta, line_no, trigger, max_value, actual_value) do
    format_issue issue_meta,
      message: "Function is too complex (CC is #{actual_value}, max is #{max_value}).",
      trigger: trigger,
      line_no: line_no,
      severity: Severity.compute(actual_value, max_value)
  end
end
