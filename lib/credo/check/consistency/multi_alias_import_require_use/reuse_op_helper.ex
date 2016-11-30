defmodule Credo.Check.Consistency.MultiAliasImportRequireUse.ReuseOpHelper do
  
  @reuse_ops [:alias, :import, :require, :use]
  @name_delimiter "."

  def multi_names({:defmodule, _, _arguments} = ast) do
    ast
    |> Credo.Code.postwalk(&multi_names_only/2)
    |> Enum.uniq
  end  

  def single_names({:defmodule, _, _arguments} = ast) do
    ast
    |> Credo.Code.postwalk(&single_names_only/2)
    |> Enum.uniq
  end  

  def multiple_single_names(ast) do
    ast
    |> single_names
    |> group_single_names
  end  

  defp group_single_names(names) do
    names
    |> Enum.group_by(fn %{name: name, reuse_op: reuse_op} -> {base_name(name), reuse_op} end)
    |> Enum.filter(fn {k, v} -> Enum.count(v) > 1 end)
  end
  
  for op <- @reuse_ops do
    defp single_names_only({unquote(op) = op, [line: line_no], [{:__aliases__, _, mod_list}]} = ast, usages) do
      {ast, usages ++ [%{reuse_op: op, name: Credo.Code.Name.full(mod_list), line_no: line_no}]}
    end

    defp single_names_only({unquote(op) = op, _, [{{:., _, [{:__aliases__, _, mod_list}, :{}]}, _, multi_mod_list}]} = ast, usages) do
      {ast, usages}
    end

    defp multi_names_only({unquote(op) = op, _, [{{:., [line: line_no], [{:__aliases__, _, [top_level|_] = mod_list}, :{}]}, _, multi_mod_list}]} = ast, usages) do
      names = multi_mod_list
        |> Enum.map(fn(tuple) -> Credo.Code.Name.full([Credo.Code.Name.full(mod_list), Credo.Code.Name.full(tuple)]) end)            
      {ast, usages ++ [%{reuse_op: op, names: names, line_no: line_no}]}
    end  
  end

  defp single_names_only(ast, usages) do
    {ast, usages}
  end

  defp multi_names_only(ast, usages) do
    {ast, usages}
  end  
  
  defp base_name(name) do
    parts = String.split(name, @name_delimiter)
    parts
    |> Enum.slice(0, Enum.count(parts) - 1)
    |> Enum.join(@name_delimiter)    
  end

end