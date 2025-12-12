defmodule Credo.Check.Refactor.CyclomaticComplexity do
  use Credo.Check,
    id: "EX4006",
    param_defaults: [max_complexity: 9],
    explanations: [
      check: """
      Cyclomatic complexity (CC) is a software complexity metric closely
      correlated with coding errors.

      If a function feels like it's gotten too complex, it more often than not also
      has a high CC value. So, if anything, this is useful to convince team members
      and bosses of a need to refactor parts of the code based on "objective"
      metrics.
      """,
      params: [
        max_complexity: "The maximum cyclomatic complexity a function should have."
      ]
    ]

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
    case: 1,
    cond: 1
  ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  # exception for `__using__` macros
  defp walk({:defmacro, _, [{:__using__, _, _}, _]} = ast, ctx) do
    {ast, ctx}
  end

  for op <- @def_ops do
    defp walk({unquote(op), meta, arguments} = ast, ctx) when is_list(arguments) do
      complexity = round(complexity_for(ast))

      if complexity > ctx.params.max_complexity do
        fun_name = Credo.Code.Module.def_name(ast)

        {ast, put_issue(ctx, issue_for(ctx, meta, fun_name, complexity))}
      else
        {ast, ctx}
      end
    end
  end

  defp walk(ast, ctx) do
    {ast, ctx}
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
    defp traverse_complexity({unquote(op) = op, _meta, arguments} = ast, complexity)
         when is_list(arguments) do
      {ast, complexity + @op_complexity_map[op]}
    end
  end

  for op <- @double_condition_ops do
    defp traverse_complexity({unquote(op) = op, _meta, arguments} = ast, complexity)
         when is_list(arguments) do
      {ast, complexity + @op_complexity_map[op]}
    end
  end

  for op <- @multiple_condition_ops do
    defp traverse_complexity({unquote(op), _meta, nil} = ast, complexity) do
      {ast, complexity}
    end

    defp traverse_complexity(
           {unquote(op) = op, _meta, arguments} = ast,
           complexity
         )
         when is_list(arguments) do
      block_cc =
        arguments
        |> Credo.Code.Block.do_block_for!()
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
      |> List.wrap()
      |> Enum.count()

    count * @op_complexity_map[op]
  end

  defp issue_for(ctx, meta, trigger, actual_value) do
    max_value = ctx.params.max_complexity

    format_issue(
      ctx,
      message:
        "Function is too complex (cyclomatic complexity is #{actual_value}, max is #{max_value}).",
      trigger: trigger,
      line_no: meta[:line],
      severity: Severity.compute(actual_value, max_value)
    )
  end
end
