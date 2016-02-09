defmodule Credo.Check.FindLintAttributes do
  @moduledoc """
  """

  use Credo.Check, run_on_all: true, base_priority: :high

  alias Credo.SourceFile
  alias Credo.Check.CodeHelper
  alias Credo.Check.LintAttribute

  @doc false
  def run(source_files, params \\ []) when is_list(source_files) do
    source_files
    |> Enum.map(&run_source_file/1)
  end

  def run_source_file(source_file) do
    lint_attributes =
      Credo.Code.traverse(source_file, &traverse(&1, &2, source_file))
    %SourceFile{source_file | lint_attributes: lint_attributes}
  end

  defp traverse({:defmodule, _meta, arguments} = ast, attribute_list, source_file) do
    found_attributes =
      ast
      |> CodeHelper.calls_in_do_block()
      |> process_calls(nil, [])
      |> Enum.map(fn(lint) ->
          {_, scope} = CodeHelper.scope_for(source_file, line: lint.line)
          %LintAttribute{lint | scope: scope}
        end)

    {ast, attribute_list ++ found_attributes}
  end
  defp traverse(ast, attribute_list, _source_file) do
    {ast, attribute_list}
  end

  def process_calls([], _, attribute_list), do: attribute_list
  def process_calls([head|tail], nil, attribute_list) do
    current_lint_attribute =
      case head do
        {:@, _, [{:lint, _, _}]} = ast ->
          LintAttribute.from_ast(ast)
        _ ->
          nil
      end
    process_calls(tail, current_lint_attribute, attribute_list)
  end
  def process_calls([head|tail], current_lint_attribute, attribute_list) do
    case head do
      {:@, meta, [{:lint, _, arguments}]} ->
        # TODO: warn that a new lint attribute was read while one was still active
        current_lint_attribute =
          %LintAttribute{meta: meta, arguments: arguments}
      {op, meta, _} when op in [:def, :defp] ->
        current_lint_attribute =
          %LintAttribute{current_lint_attribute | line: meta[:line]}
        attribute_list = [current_lint_attribute | attribute_list]
        current_lint_attribute = nil
      _ ->
        nil
    end
    process_calls(tail, current_lint_attribute, attribute_list)
  end
end
