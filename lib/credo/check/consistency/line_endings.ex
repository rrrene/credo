defmodule Credo.Check.Consistency.LineEndings do
  use Credo.Check,
    run_on_all: true,
    base_priority: :high,
    tags: [:formatter],
    param_defaults: [
      force: nil
    ],
    explanations: [
      check: """
      Windows and Linux/macOS systems use different line-endings in files.

      It seems like a good idea not to mix these in the same codebase.

      While this is not necessarily a concern for the correctness of your code,
      you should use a consistent style throughout your codebase.
      """,
      params: [
        force: "Force a choice, values can be `:unix` or `:windows`."
      ]
    ]

  @collector Credo.Check.Consistency.LineEndings.Collector

  @doc false
  @impl true
  def run_on_all_source_files(exec, source_files, params) do
    @collector.find_and_append_issues(source_files, exec, params, &issues_for/3)
  end

  defp issues_for(expected, source_file, params) do
    first_line_with_issue = @collector.first_line_with_issue(expected, source_file)

    message =
      case expected do
        :unix ->
          "File is using windows line endings while most of the files use unix line endings."

        :windows ->
          "File is using unix line endings while most of the files use windows line endings."
      end

    trigger =
      case expected do
        :unix -> "\r\n"
        :windows -> "\n"
      end

    source_file
    |> IssueMeta.for(params)
    |> format_issue(message: message, line_no: first_line_with_issue, trigger: trigger)
    |> List.wrap()
  end
end
