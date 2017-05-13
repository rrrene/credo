defmodule Credo.Check.Consistency.MultiAliasImportRequireUse.Multi do
  use Credo.Check.CodePattern

  alias Credo.Check.Consistency.MultiAliasImportRequireUse.ReuseOpHelper

  def property_value, do: :multi_alias_import_require_use

  def property_value_for(%SourceFile{filename: filename} = source_file, _params) do
    source_file
    |> SourceFile.ast
    |> ReuseOpHelper.multi_names
    |> Enum.map(&(property_value_for_namespace(&1, filename)))
  end

  defp property_value_for_namespace(%{names: names, line_no: line_no, reuse_op: reuse_op}, filename) do
    PropertyValue.for(property_value(), %{line_no: line_no, filename: filename, names: names, reuse_op: reuse_op})
  end
end
