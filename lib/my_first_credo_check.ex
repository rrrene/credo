defmodule Lib.MyFirstCredoCheck do
  @moduledoc """
    Checks all lines for a given Regex.

    This is fun!
  """

  @explanation [
    check: @moduledoc,
    params: [
      regex: "All lines matching this Regex will yield an issue.",
    ]
  ]
  @default_params [
    regex: ~r/Creeeedo/, # our check will find this line.
  ]

  @def_ops [:def, :defp, :defmacro]

  use Credo.Check, base_priority: :high, category: :custom #, exit_status: 0

  def run(%SourceFile{ast: ast, lines: lines} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    line_regex = params |> Params.get(:regex, @default_params)

    Enum.reduce(lines, [], &process_line(&1, &2, line_regex, issue_meta))
  end

  defp process_line({line_no, line}, issues, line_regex, issue_meta) do
    case Regex.run(line_regex, line) do
      nil -> issues
      matches ->
        trigger = matches |> List.last
        new_issue = issue_for(issue_meta, line_no, trigger)
        [new_issue | issues]
    end
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue issue_meta,
      message: "OMG! This line matches our Regexp!",
      line_no: line_no,
      trigger: trigger
  end
end
