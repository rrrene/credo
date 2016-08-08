defmodule Credo.Check.Warning.CallbacksArity do
  @moduledoc """
  The arities of the callback functions should correspond respectively
  to the arities of the functions from behaviour module

  Example:

  defmodule Example
    use GenServer

    def handle_call(:x, state) do
      # Notice the missing "from" parameter
      {:reply, :y, state}
    end
  end

  Should warn on Example.handle_call/2 being similar to Example.handle_call/3
  since the @behaviour added via use GenServer has a @callback handle_call/3.
  """

  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :normal

  def run(%SourceFile{ast: ast} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    behaviours = Credo.Code.Module.behaviours(ast)

    callbacks =
      behaviours
      |> Enum.reduce([], fn(behaviour, acc) ->
        [Credo.Code.Module.callbacks(behaviour) | acc]
      end)
      |> List.flatten
      |> Enum.uniq

    Credo.Code.prewalk(ast, &find_issues(&1, &2, issue_meta, callbacks))
  end

  defp find_issues({:def, meta, arguments} = ast, issues, issue_meta, callbacks) when is_list(arguments) do
    name = ast |> Credo.Code.Module.def_name
    arity = ast |> Credo.Code.Module.def_arity

    if conflicts_with_callbacks?(name, arity, callbacks) do
      {ast, issues ++ [issue_for(issue_meta, meta[:line], name)]}
    else
      {ast, issues}
    end
  end
  defp find_issues(ast, issues, _, _) do
    {ast, issues}
  end

  defp conflicts_with_callbacks?(name, arity, callbacks) do
    callbacks
    |> Enum.filter(&(elem(&1, 0) == name))
    |> Keyword.values
    |> Enum.any?(&(&1 != arity))
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue issue_meta,
      message: "The arities of the callback functions should correspond respectively to the arities of the functions from behaviour module",
      trigger: trigger,
      line_no: line_no
  end
end
