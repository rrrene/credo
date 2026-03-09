defmodule Credo.Check.Refactor.Nesting do
  use Credo.Check,
    id: "EX4021",
    param_defaults: [max_nesting: 2],
    explanations: [
      check: """
      Code should not be nested more than once inside a function.

          defmodule CredoSampleModule do
            def some_function(parameter1, parameter2) do
              Enum.reduce(var1, list, fn({_hash, nodes}, list) ->
                filenames = nodes |> Enum.map(&(&1.filename))

                Enum.reduce(list, [], fn(item, acc) ->
                  if item.filename do
                    item               # <-- this is nested 3 levels deep
                  end
                  acc ++ [item]
                end)
              end)
            end
          end

      At this point it might be a good idea to refactor the code to separate the
      different loops and conditions.
      """,
      params: [
        max_nesting: "The maximum number of levels code should be nested."
      ]
    ]

  @def_ops [:def, :defp, :defmacro]
  @nest_ops [:if, :unless, :case, :cond, :fn, :for, :with]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  for op <- @def_ops do
    defp walk(
           {unquote(op) = op, meta, arguments} = ast,
           %{params: %{max_nesting: max_nesting}} = ctx
         )
         when is_list(arguments) do
      arguments
      |> find_depth([], meta[:line], op)
      |> handle_depth(ast, ctx, max_nesting)
    end
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp handle_depth(nil, ast, ctx, _max_nesting) do
    {ast, ctx}
  end

  defp handle_depth({depth, line_no, trigger}, ast, ctx, max_nesting) when depth > max_nesting do
    {ast, put_issue(ctx, issue_for(ctx, line_no, trigger, max_nesting, depth))}
  end

  defp handle_depth(_, ast, ctx, _max_nesting) do
    {ast, ctx}
  end

  # Searches for the depth level and returns a tuple `{depth, line_no, trigger}`
  # where the greatest depth was reached.
  defp find_depth(arguments, nest_list, line_no, trigger) when is_list(arguments) do
    arguments
    |> Credo.Code.Block.all_blocks_for!()
    |> Enum.flat_map(fn block ->
      block
      |> List.wrap()
      |> Enum.map(&find_depth(&1, nest_list, line_no, trigger))
    end)
    |> Enum.sort()
    |> List.last()
  end

  for op <- @nest_ops do
    defp find_depth({unquote(op) = op, meta, arguments}, nest_list, _, _)
         when is_list(arguments) do
      arguments
      |> Enum.map(&find_depth(&1, nest_list ++ [op], meta[:line], op))
      |> Enum.sort()
      |> List.last()
    end
  end

  defp find_depth({atom, _meta, arguments}, nest_list, line_no, trigger)
       when (is_atom(atom) or is_tuple(atom)) and is_list(arguments) do
    arguments
    |> Enum.map(&find_depth(&1, nest_list, line_no, trigger))
    |> Enum.sort()
    |> List.last()
  end

  defp find_depth(_, nest_list, line_no, trigger) do
    {Enum.count(nest_list), line_no, trigger}
  end

  defp issue_for(ctx, line_no, trigger, max_value, actual_value) do
    format_issue(
      ctx,
      message:
        "Function body is nested too deep (max depth is #{max_value}, was #{actual_value}).",
      line_no: line_no,
      trigger: trigger,
      severity: Severity.compute(actual_value, max_value)
    )
  end
end
