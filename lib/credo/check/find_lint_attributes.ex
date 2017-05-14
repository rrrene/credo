defmodule Credo.Check.FindLintAttributes do
  @moduledoc """
  """
  @explanation nil

  use Credo.Check, run_on_all: true, base_priority: :high

  alias Credo.Check.CodeHelper
  alias Credo.Check.LintAttribute

  @doc false
  def run(source_files, _exec, _params) when is_list(source_files) do
    Enum.map(source_files, &find_lint_attributes/1)
  end

  def find_lint_attributes(source_file) do
    lint_attributes =
      Credo.Code.prewalk(source_file, &traverse(&1, &2, source_file))

    {source_file.filename, lint_attributes}
  end

  @lint false
  defp traverse({:defmodule, _meta, _arguments} = ast, attribute_list, source_file) do
    found_attributes =
      ast
      |> CodeHelper.calls_in_do_block()
      |> process_calls(nil, [])
      |> Enum.map(fn(lint) ->
          Credo.CLI.Output.UI.warn [:orange, "#{source_file.filename}:#{lint.line} - @lint is deprecated."]

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
      # a lint attribute was found
      {:@, meta, [{:lint, _, arguments}]} ->
        # TODO: warn that a new lint attribute was read while one was still active
        process_calls(tail, %LintAttribute{meta: meta, arguments: arguments}, attribute_list)
      # another module attribute was found
      {:@, _meta, _} ->
        process_calls(tail, current_lint_attribute, attribute_list)
      # an operation was found (at the module level)
      {op, meta, arguments} when is_atom(op) and is_list(arguments) ->
        attribute_list = [%LintAttribute{current_lint_attribute | line: meta[:line]} | attribute_list]
        process_calls(tail, nil, attribute_list)
      _ ->
        process_calls(tail, current_lint_attribute, attribute_list)
    end
  end
end
