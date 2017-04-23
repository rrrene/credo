defmodule Credo.Check.Consistency.MultiAliasImportRequireUse.ReuseOpHelper do
  alias Credo.Code.Name

  @reuse_ops [:alias, :import, :require, :use]
  @name_delimiter "."

  def multi_names({:defmodule, _, _arguments} = ast) do
    ast
    |> Credo.Code.postwalk(&multi_names_only/2)
    |> Enum.uniq
  end
  def multi_names(_), do: []

  def single_names({:defmodule, _, _arguments} = ast) do
    ast
    |> Credo.Code.postwalk(&single_names_only/2)
    |> Enum.uniq
  end
  def single_names(_), do: []

  def multiple_single_names(ast) do
    ast
    |> single_names
    |> group_single_names
  end

  defp group_single_names(names) do
    names
    |> Enum.group_by(fn %{name: name, reuse_op: reuse_op} -> {base_name(name), reuse_op} end)
    |> Enum.filter(fn {_, v} -> Enum.count(v) > 1 end)
  end

  for op <- @reuse_ops do
    defp single_names_only({unquote(op) = op, [line: line_no], [{:__aliases__, _, mod_list}]} = ast, usages) when length(mod_list) > 1 do
      {ast, usages ++ [%{reuse_op: op, name: Name.full(mod_list), line_no: line_no}]}
    end

    defp single_names_only({unquote(op), _, [{{:., _, [{:__aliases__, _, _mod_list}, :{}]}, _, _multi_mod_list}]} = ast, usages) do
      {ast, usages}
    end
  end
  defp single_names_only(ast, usages) do
    {ast, usages}
  end

  for op <- @reuse_ops do
    defp multi_names_only({unquote(op) = op, _, [{{:., [line: line_no], [{:__aliases__, _, mod_list}, :{}]}, _, multi_mod_list}]} = ast, usages) do
      names =
        Enum.map(multi_mod_list, fn({:__aliases__, _, last_names}) ->
          Name.full(mod_list ++ last_names)
        end)

      {ast, usages ++ [%{reuse_op: op, names: names, line_no: line_no}]}
    end
  end
  defp multi_names_only(ast, usages) do
    {ast, usages}
  end

  defp base_name(name) do
    name
    |> String.split(@name_delimiter)
    |> Enum.slice(0..-2)
    |> Enum.join(@name_delimiter)
  end
end
