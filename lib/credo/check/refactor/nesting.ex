defmodule Credo.Check.Refactor.Nesting do
  @moduledoc """
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
  """

  @explanation [
    check: @moduledoc,
    params: [
      max_nesting: "The maximum number of levels code should be nested."
    ]
  ]
  @default_params [max_nesting: 2]

  @def_ops [:def, :defp, :defmacro]
  @nest_ops [:if, :unless, :case, :cond, :fn]

  alias Credo.Check.CodeHelper

  use Credo.Check

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    max_nesting = Params.get(params, :max_nesting, @default_params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta, max_nesting))
  end

  for op <- @def_ops do
    defp traverse({unquote(op) = op, meta, arguments} = ast, issues, issue_meta, max_nesting) when is_list(arguments) do
      arguments
      |> find_depth([], meta[:line], op)
      |> handle_depth(ast, issue_meta, issues, max_nesting)
    end
  end
  defp traverse(ast, issues, _issue_meta, _max_nesting) do
    {ast, issues}
  end

  def handle_depth(nil, ast, _issue_meta, issues, _max_nesting) do
    {ast, issues}
  end
  def handle_depth({depth, line_no, trigger}, ast, issue_meta, issues, max_nesting) do
    if depth > max_nesting do
      {ast, issues ++ [issue_for(issue_meta, line_no, trigger, max_nesting, depth)]}
    else
      {ast, issues}
    end
  end

  # Searches for the depth level and returns a tuple `{depth, line_no, trigger}`
  # where the greatest depth was reached.
  defp find_depth(arguments, nest_list, line_no, trigger) when is_list(arguments) do
    arguments
    |> CodeHelper.do_block_for!
    |> List.wrap
    |> Enum.map(&find_depth(&1, nest_list, line_no, trigger))
    |> Enum.sort
    |> List.last
  end
  for op <- @nest_ops do
    defp find_depth({unquote(op) = op, meta, arguments}, nest_list, _line_no, _trigger) when is_list(arguments) do
      arguments
      |> Enum.map(&find_depth(&1, nest_list ++ [op], meta[:line], op))
      |> Enum.sort
      |> List.last
    end
  end
  defp find_depth({atom, _meta, arguments}, nest_list, line_no, trigger) when (is_atom(atom) or is_tuple(atom)) and is_list(arguments) do
    arguments
    |> Enum.map(&find_depth(&1, nest_list, line_no, trigger))
    |> Enum.sort
    |> List.last
  end
  defp find_depth(_, nest_list, line_no, trigger) do
    {Enum.count(nest_list), line_no, trigger}
  end

  def issue_for(issue_meta, line_no, trigger, max_value, actual_value) do
    format_issue issue_meta,
      message: "Function body is nested too deep (max depth is #{max_value}, was #{actual_value}).",
      line_no: line_no,
      trigger: trigger,
      severity: Severity.compute(actual_value, max_value)
  end
end
