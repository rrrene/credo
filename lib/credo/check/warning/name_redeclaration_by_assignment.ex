defmodule Credo.Check.Warning.NameRedeclarationByAssignment do
  @moduledoc """
  The names of local variables should not be the same as names of functions
  or macros in the same module or in `Kernel`.

  Example:

      def handle_something do
        time = 42
        IO.puts time  # not clear if we are talking about time/0 or time
      end

      def time do
        TimeHelper.now
      end

  This might not seem like a big deal, especially for small functions.
  But there is no downside to avoiding it, especially in the case of functions
  with arity `/0` and Kernel functions.

  True story: You might pattern match on a parameter geniusly called `node`.
  Then you remove that match for some reason and rename the parameter to `_node`
  because it is no longer used.
  Later you reintroduce the pattern match on `node` but forget to also rename
  `_node` and suddenly the match is actually against `Kernel.node/0` and has the
  weirdest side effects.

  This happens. I mean, to a friend of mine, it did. Who ... later told me.
  """

  @explanation [check: @moduledoc]
  @kernel_fun_names [
    :make_ref,
    :node,
    :self
  ]
  @kernel_macro_names [
  ]
  @excluded_names [:_, :sigil_r, :sigil_R]

  alias Credo.Code
  alias Credo.Code.Module

  use Credo.Check, base_priority: :high

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    source_file
    |> Code.prewalk(&traverse(&1, &2, issue_meta, @excluded_names))
    |> List.flatten
    |> Enum.reject(&is_nil/1)
  end

  defp traverse({:defmodule, _, _} = ast, issues, issue_meta, excluded_names) do
    names = %{
      def_names: Module.def_names_with_op(ast, 0),
      excluded_names: excluded_names
    }

    new_issues = Code.prewalk(ast, &mod_traverse(&1, &2, issue_meta, names))

    {ast, issues ++ new_issues}
  end
  defp traverse(ast, issues, _issue_meta, _excluded_names) do
    {ast, issues}
  end

  defp mod_traverse({:=, _meta, [lhs, _rhs]} = ast, issues, issue_meta, %{} = names) do
    case find_issue(lhs, issue_meta, names.def_names, names.excluded_names) do
      nil -> {ast, issues}
      list when is_list(list) -> {ast, issues ++ list}
      new_issue -> {ast, issues ++ [new_issue]}
    end
  end
  defp mod_traverse(ast, issues, _issue_meta, _names) do
    {ast, issues}
  end

  def find_issue({:->, _meta2, [lhs, _rhs]}, issue_meta, def_names, excluded_names) do
    find_issue(lhs, issue_meta, def_names, excluded_names)
  end
  def find_issue({:%{}, _meta2, keywords}, issue_meta, def_names, excluded_names) do
    Enum.map(keywords, fn
      {_lhs, rhs} ->
        find_issue(rhs, issue_meta, def_names, excluded_names)
      _ ->
        nil
    end)
  end
  def find_issue({:{}, _meta2, tuple_list}, issue_meta, def_names, excluded_names) do
    find_issue(tuple_list, issue_meta, def_names, excluded_names)
  end
  def find_issue({:%, _meta, [{:__aliases__, _meta1, _mod}, map]}, issue_meta, def_names, excluded_names) do
    find_issue(map, issue_meta, def_names, excluded_names)
  end
  def find_issue({name, meta, _}, issue_meta, def_names, excluded_names) when is_atom(name) do
    line_no = meta[:line]
    def_op = find_def_op(def_names, name)

    cond do
      Enum.member?(excluded_names, name) ->
        nil
      def_op ->
        issue_for(issue_meta, line_no, name, message_for_def(def_op))
      Enum.member?(@kernel_fun_names, name) ->
        issue_for(issue_meta, line_no, name, "the `Kernel.#{name}` function")
      Enum.member?(@kernel_macro_names, name) ->
        issue_for(issue_meta, line_no, name, "the `Kernel.#{name}` macro")
      true ->
        nil
    end
  end
  def find_issue(list, issue_meta, def_names, excluded_names) when is_list(list) do
    Enum.map(list, &find_issue(&1, issue_meta, def_names, excluded_names))
  end
  def find_issue(tuple, issue_meta, def_names, excluded_names) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list
    |> Enum.map(&find_issue(&1, issue_meta, def_names, excluded_names))
  end
  def find_issue(_, _, _, _) do
    nil
  end

  defp find_def_op(def_names, name) do
    def_names
    |> Enum.find(fn({def_name, _op}) -> def_name == name end)
    |> extract_def_op
  end

  defp extract_def_op({_, op}), do: op
  defp extract_def_op(nil), do: nil

  defp message_for_def(op) do
    case op do
      :def -> "a function in the same module"
      :defp -> "a private function in the same module"
      :defmacro -> "a macro in the same module"
      _ -> "ERROR"
    end
  end

  defp issue_for(issue_meta, line_no, trigger, what) do
    format_issue issue_meta,
      message: "Assigned variable `#{trigger}` has same name as #{what}.",
      trigger: trigger,
      line_no: line_no
  end
end
