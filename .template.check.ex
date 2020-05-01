defmodule <%= @check_name %> do
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

  # you can configure the basics of your check via the `use Credo.Check` call
  use Credo.Check, base_priority: :high, category: :custom, exit_status: 0

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    lines = SourceFile.lines(source_file)

    # IssueMeta helps us pass down both the source_file and params of a check
    # run to the lower levels where issues are created, formatted and returned
    issue_meta = IssueMeta.for(source_file, params)

    # we use the `params` parameter and the `Params` module to extract a
    # configuration parameter from `.credo.exs` while also providing a
    # default value
    line_regex = params |> Params.get(:regex, __MODULE__)

    # Finally, we can run our custom made analysis.
    # In this example, we look for lines in source code matching our regex:
    Enum.reduce(lines, [], &process_line(&1, &2, line_regex, issue_meta))
  end

  defp process_line({line_no, line}, issues, line_regex, issue_meta) do
    case Regex.run(line_regex, line) do
      nil -> issues
      matches ->
        trigger = matches |> List.last
        new_issue = issue_for(issue_meta, line_no, trigger)
        [new_issue] ++ issues
    end
  end

  defp issue_for(issue_meta, line_no, trigger) do
    # format_issue/2 is a function provided by Credo.Check to help us format the
    # found issue
    format_issue issue_meta,
      message: "OMG! This line matches our Regexp in @default_params!",
      line_no: line_no,
      trigger: trigger
  end
end
