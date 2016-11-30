defmodule Credo.Check.Consistency.MultiAliasImportRequireUse.Multi do
  use Credo.Check.CodePattern

  alias Credo.Check.Consistency.MultiAliasImportRequireUse.ReuseOpHelper 

  def property_value, do: :multi_alias_import_require_use

  def property_value_for(%SourceFile{ast: ast, filename: filename}, _params) do
    ReuseOpHelper.multi_names(ast)
    |> Enum.map(fn name -> property_value_for_namespace(name, filename) end)    
  end

  defp property_value_for_namespace(%{names: names, line_no: line_no, reuse_op: reuse_op}, filename) do
    PropertyValue.for(property_value, %{line_no: line_no, filename: filename, names: names, reuse_op: reuse_op})
  end

  defp property_value_for_imported_namespace(x, y), do: nil

end