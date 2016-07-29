defmodule Credo.Check.Consistency.ExceptionNames do
  @moduledoc """
  Exception names should end with a common suffix like "Error".

  Try to name your exception modules consistently:

      defmodule BadCodeError do
        defexception [:message]
      end

      defmodule ParserError do
        defexception [:message]
      end

  Inconsistent use should be avoided:

      defmodule BadHTTPResponse do
        defexception [:message]
      end

      defmodule HTTPHeaderException do
        defexception [:message]
      end

  While this is not necessarily a concern for the correctness of your code,
  you should use a consistent style throughout your codebase.
  """

  @explanation [check: @moduledoc]
  @code_patterns [
    Credo.Check.Consistency.ExceptionNames.PrefixAndSuffixCollector
  ]

  alias Credo.Check.Consistency.Helper
  alias Credo.Code.Module
  alias Credo.Code.Name

  use Credo.Check, run_on_all: true, base_priority: :high

  def run(source_files, params \\ []) when is_list(source_files) do
    {property_tuples, most_picked} =
      source_files
      |> Helper.run_code_patterns(@code_patterns, params)

    count =
      property_tuples
      |> Enum.reduce(0, fn({prop_list, _}, acc) ->
          acc + Enum.count(prop_list)
        end)

    if count > 2 do # we found more than one prefix and one suffix
      {property_tuples, most_picked}
      |> Helper.append_issues_via_issue_service(&check_for_issues/5, params)
    end

    :ok
  end

  defp check_for_issues(_issue_meta, _actual_prop, nil, _picked_count, _total_count), do: nil
  defp check_for_issues(_issue_meta, [], _expected_prop, _picked_count, _total_count), do: nil
  defp check_for_issues(issue_meta, _actual_prop, expected_prop, _picked_count, _total_count) do
    source_file = IssueMeta.source_file(issue_meta)
    case expected_prop do
      {prefix, :prefix} ->
        source_file
        |> find_exception_modules_without_prefix(prefix)
        |> issues_for_wrong(:prefix, issue_meta, prefix)
      {suffix, :suffix} ->
        source_file
        |> find_exception_modules_without_suffix(suffix)
        |> issues_for_wrong(:suffix, issue_meta, suffix)
      _ -> nil
    end
  end

  defp find_exception_modules_without_suffix(%SourceFile{ast: ast}, suffix) do
    ast
    |> Credo.Code.prewalk(&find_exception_modules(&1, &2))
    |> Enum.reject(&name_with_suffix?(&1, suffix))
  end

  defp find_exception_modules_without_prefix(%SourceFile{ast: ast}, prefix) do
    ast
    |> Credo.Code.prewalk(&find_exception_modules(&1, &2))
    |> Enum.reject(&name_with_prefix?(&1, prefix))
  end

  defp find_exception_modules({:defmodule, _meta, [{:__aliases__, _, _name_arr}, _arguments]} = ast, exception_names) do
    if Module.exception?(ast) do
      {ast, exception_names ++ [ast]}
    else
      {ast, exception_names}
    end
  end
  defp find_exception_modules(ast, exception_names) do
    {ast, exception_names}
  end

  defp name_with_suffix?(module_ast, suffix) do
    module_ast |> Module.name |> Name.split_pascal_case |> List.last == suffix
  end

  defp name_with_prefix?(module_ast, prefix) do
    module_ast |> Module.name |> Name.split_pascal_case |> List.first == prefix
  end

  defp issues_for_wrong(exception_list, prefix_or_suffix, issue_meta, suffix) do
    exception_list
    |> Enum.map(&issue_for_wrong(&1, prefix_or_suffix, issue_meta, suffix))
    |> Enum.reject(&is_nil/1)
  end

  defp issue_for_wrong({:defmodule, meta, _} = ast, prefix_or_suffix, issue_meta, expected) do
    trigger = Module.name(ast)
    format_issue issue_meta,
      message: message_for(prefix_or_suffix, expected, trigger),
      line_no: meta[:line],
      trigger: trigger
  end

  def message_for(:prefix, expected, trigger) do
    """
    Exception modules should be named consistently.
    It seems your strategy is to prefix them with `#{expected}`,
    but `#{trigger}` does not follow that convention."
    """ |> to_one_line
  end
  def message_for(:suffix, expected, trigger) do
    """
    Exception modules should be named consistently.
    It seems your strategy is to have `#{expected}` as a suffix,
    but `#{trigger}` does not follow that convention.
    """ |> to_one_line
  end

  def to_one_line(str), do: str |> String.split |> Enum.join(" ")
end
