defmodule Credo.Check.Consistency.MultiAliasImportRequireUse.Single do
  use Credo.Check.CodePattern

  alias Credo.Check.Consistency.MultiAliasImportRequireUse.ReuseOpHelper

  def property_value, do: :single_alias_import_require_use

  def property_value_for(source_file, _params) do
    source_file
    |> SourceFile.ast
    |> ReuseOpHelper.multiple_single_names
    |> Enum.map(&property_value_for_namespace/1)
  end

  defp property_value_for_namespace({{namespace, reuse_op}, imports}) when length(imports) > 1 do
    line_no =
      imports
      |> Enum.map(&(&1[:line_no]))
      |> Enum.max
    PropertyValue.for(property_value(), line_no: line_no, reuse_op: reuse_op, namespace: namespace)
  end
end
