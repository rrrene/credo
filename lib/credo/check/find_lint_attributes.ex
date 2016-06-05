defmodule Credo.Check.FindLintAttributes do
  @moduledoc """
  """
  @explanation nil

  use Credo.Check, run_on_all: true, base_priority: :high

  alias Credo.SourceFile
  alias Credo.Check.CodeHelper
  alias Credo.Check.LintAttribute

  @doc false
  def run(source_files, _params) when is_list(source_files) do
    source_files
    |> Enum.map(&run_source_file/1)
  end

  def run_source_file(source_file) do
    lint_attributes =
      Credo.Code.traverse(source_file, &traverse(&1, &2, source_file))
    %SourceFile{source_file | lint_attributes: lint_attributes}
  end

  defp traverse({:defmodule, _meta, _arguments} = ast, attribute_list, source_file) do
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

  def process_calls([], _, attributes), do: attributes
  def process_calls([{:@, _, [{:lint, _, _}] = ast} | tail], nil, attributes) do
    current_lint_attribute = LintAttribute.from_ast(ast)
    process_calls(tail, current_lint_attribute, attributes)
  end
  def process_calls([{:@, _, [{:lint, _, _}] = ast} | tail], _old, attributes) do
    # TODO: warn that a new lint attribute was read while one was still active
    current_lint_attribute = LintAttribute.from_ast(ast)
    process_calls(tail, current_lint_attribute, attributes)
  end
  def process_calls([{op, meta, _}|tail], current_attr, attributes)
      when op in [:def, :defp] do
    updated = %LintAttribute{current_attr | line: meta[:line]}
    process_calls(tail, nil, [updated | attributes])
  end
end
