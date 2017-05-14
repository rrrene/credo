defmodule Credo.Check.Consistency.MultiAliasImportRequireUse do
  @moduledoc """
  When using alias, import, require or use for multiple names from the same
  namespace, you have two options:

  Use single instructions per name:

    alias Ecto.Query
    alias Ecto.Schema
    alias Ecto.Multi

  or use one multi instruction per namespace:

    alias Ecto.{Query, Schema, Multi}

  While this is not necessarily a concern for the correctness of your code,
  you should use a consistent style throughout your codebase.
  """

  @explanation [check: @moduledoc]

  @code_patterns [
    Credo.Check.Consistency.MultiAliasImportRequireUse.Multi,
    Credo.Check.Consistency.MultiAliasImportRequireUse.Single
  ]

  alias Credo.Check.Consistency.Helper

  use Credo.Check, run_on_all: true, base_priority: :high

  @doc false
  def run(source_files, exec, params \\ []) when is_list(source_files) do
    source_files
    |> Helper.run_code_patterns(@code_patterns, params)
    |> Helper.append_issues_via_issue_service(&issue_for/5, params, exec)
    :ok
  end

  defp issue_for(_issue_meta, _actual_props, nil, _picked_count, _total_count), do: nil
  defp issue_for(_issue_meta, [], _expected_prop, _picked_count, _total_count), do: nil
  defp issue_for(issue_meta, {_x, _value, meta} = actual_prop, _expected_prop, _picked_count, _total_count) do
    format_issue issue_meta,
      message: message_for(actual_prop),
      line_no: meta[:line_no]
  end

  defp message_for({_, :single_alias_import_require_use, _}) do
    "Most of the time you are using the multi-alias/require/import/use syntax, but here you are using multiple single directives"
  end
  defp message_for({_, :multi_alias_import_require_use, _}) do
    "Most of the time you are using the multiple single line alias/require/import/use directives but here you are using the multi-alias/require/import/use syntax"
  end
end
