defmodule Credo.Check.Readability.MaxLineLength do
  @moduledoc """
    Checks for the length of lines.

    Can optionally ignore function definitions and (multi-)line strings.
  """

  @explanation [check: @moduledoc]
  @default_params [
      max_length: 80,
      ignore_definitions: true,
      ignore_strings: true
    ]

  @def_ops Application.get_env(:credo, :def_ops)

  use Credo.Check, base_priority: :low

  def run(%SourceFile{ast: ast, lines: lines} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    max_length = params |> Params.get(:max_length, @default_params)
    ignore_definitions = params |> Params.get(:ignore_definitions, @default_params)
    ignore_strings = params |> Params.get(:ignore_strings, @default_params)

    definitions = Credo.Code.traverse(ast, &find_definitions/2)

    Enum.reduce(lines, [], fn({line_no, line}, issues) ->
      if String.length(line) > max_length do
        if refute_issue?(line_no, definitions, ignore_definitions, ignore_strings) do
          issues
        else
          [issue_for(line_no, max_length, line, issue_meta) | issues]
        end
      else
        issues
      end
    end)
  end

  for op <- @def_ops do
    defp find_definitions({unquote(op), meta, arguments} = ast, defintions) when is_list(arguments) do
      {ast, [meta[:line] | defintions]}
    end
  end
  defp find_definitions(ast, defintions) do
    {ast, defintions}
  end

  defp refute_issue?(line_no, definitions, ignore_definitions, ignore_strings) do
    refute = false
    if ignore_definitions do
      refute = refute || Enum.member?(definitions, line_no)
    end
    if ignore_strings do
      refute = refute || false # TODO: implement this check
    end
    refute
  end



  defp issue_for(line_no, max_length, line, issue_meta) do
    length = String.length(line)
    column = max_length + 1
    trigger = String.slice(line, max_length, length-max_length)

    format_issue issue_meta,
      message: "Line is too long (max is #{max_length}, was #{length}).",
      line_no: line_no,
      column: column,
      trigger: trigger
  end
end
