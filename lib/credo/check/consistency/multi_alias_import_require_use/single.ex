defmodule Credo.Check.Consistency.MultiAliasImportRequireUse.Single do
  use Credo.Check.CodePattern

  alias Credo.Check.Consistency.MultiAliasImportRequireUse.ReuseOpHelper

  def property_value, do: :single_alias_import_require_use

  def property_value_for(%SourceFile{filename: filename} = source_file, _params) do
    source_file
    |> SourceFile.ast
    |> ReuseOpHelper.multiple_single_names
    |> Enum.map(fn ns -> property_value_for_namespace(ns, filename) end)
  end

  defp property_value_for_namespace({{namespace, reuse_op}, imports}, filename) when length(imports) > 1 do
    line_no =
      imports
      |> Enum.map(&(&1[:line_no]))
      |> Enum.max
    PropertyValue.for(property_value(), %{line_no: line_no, reuse_op: reuse_op, filename: filename, namespace: namespace})
  end
end
