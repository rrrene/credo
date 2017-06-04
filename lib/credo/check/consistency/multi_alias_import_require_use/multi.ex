defmodule Credo.Check.Consistency.MultiAliasImportRequireUse.Multi do
  use Credo.Check.CodePattern

  alias Credo.Check.Consistency.MultiAliasImportRequireUse.ReuseOpHelper

  def property_value, do: :multi_alias_import_require_use

  def property_value_for(source_file, _params) do
    source_file
    |> SourceFile.ast
    |> ReuseOpHelper.multi_names
    |> Enum.map(&property_value_for_namespace/1)
  end

  defp property_value_for_namespace(%{names: names, line_no: line_no, reuse_op: reuse_op}) do
    PropertyValue.for(property_value(), line_no: line_no, names: names, reuse_op: reuse_op)
  end
end
