defmodule Credo.Check.Readability.MaxLineLength do
  @moduledoc """
    Checks for the length of lines.

    Ignores function definitions and (multi-)line strings by default.
  """

  @explanation [
    check: @moduledoc,
    params: [
      max_length: "The maximum number of characters a line may consist of.",
      ignore_definitions: "Set to `true` to ignore lines including function definitions.",
      ignore_specs: "Set to `true` to ignore lines including `@spec`s.",
    ]
  ]
  @default_params [
    max_length: 80,
    ignore_definitions: true,
    ignore_specs: false,
    ignore_strings: true
  ]

  @def_ops [:def, :defp, :defmacro]

  use Credo.Check, base_priority: :low

  def run(%SourceFile{ast: ast, lines: lines} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    max_length = params |> Params.get(:max_length, @default_params)
    ignore_definitions = params |> Params.get(:ignore_definitions, @default_params)
    ignore_specs = params |> Params.get(:ignore_specs, @default_params)
    ignore_strings = params |> Params.get(:ignore_strings, @default_params)

    definitions = Credo.Code.prewalk(ast, &find_definitions/2)
    specs = Credo.Code.prewalk(ast, &find_specs/2)

    Enum.reduce(lines, [], fn({line_no, line}, issues) ->
      if String.length(line) > max_length do
        if refute_issue?(line_no, definitions, ignore_definitions, specs, ignore_specs, ignore_strings) do
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
    defp find_definitions({unquote(op), meta, arguments} = ast, definitions) when is_list(arguments) do
      {ast, [meta[:line] | definitions]}
    end
  end
  defp find_definitions(ast, definitions) do
    {ast, definitions}
  end

  defp find_specs({:spec, meta, arguments} = ast, specs) when is_list(arguments) do
    {ast, [meta[:line] | specs]}
  end
  defp find_specs(ast, specs) do
    {ast, specs}
  end

  defp refute_issue?(line_no, definitions, ignore_definitions, specs, ignore_specs, ignore_strings) do
    ignore_definitions? =
      fn -> if ignore_definitions, do: Enum.member?(definitions, line_no), else: false end

    ignore_specs? =
      fn -> if ignore_specs, do: Enum.member?(specs, line_no), else: false end

    ignore_strings? = # TODO: implement ignore_strings check
      fn -> if ignore_strings, do: false, else: false end

    ignore_definitions?.() || ignore_specs?.() || ignore_strings?.()
  end



  defp issue_for(line_no, max_length, line, issue_meta) do
    line_length = String.length(line)
    column = max_length + 1
    trigger = String.slice(line, max_length, line_length - max_length)

    format_issue issue_meta,
      message: "Line is too long (max is #{max_length}, was #{line_length}).",
      line_no: line_no,
      column: column,
      trigger: trigger
  end
end
