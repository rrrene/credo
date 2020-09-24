defmodule Credo.Check.Readability.CapitalizedComments do
  @moduledoc false

  use Credo.Check,
    base_priority: :high,
    category: :readability,
    tags: [:controversial],
    param_defaults: [
      non_capitalized_sentence: ~r/\# [a-z]\S+ \S+/,
      capitalized_sentence_without_end: ~r/\# [`|"|'|0-9|A-Z]+.*[^.?!]$/,
      comment_sentence_without_end: ~r/\# \S+.*[^.?!]$/,
      excluded_paths: [],
      excluded_files: []
    ],
    explanations: [
      check: """
      Comments longer than a word need to be capitalized.

      Rules for valid single line comment:
      - Comment should start with ` or ' or " or 0-9 or A-Z
      - Comment should end with . or ? or !

      Rules for multi-line comments
      - Comment should start with ` or ' or " or 0-9 or A-Z
      - The following comment sentence can start with non-capitalized letters
      - Comment sentence ending with . or ? or ! at end are considered as end of the multi-line comments.

      Comments failing to follow these rules are considered as non-capitalized comments and marked as issues.

      Valid comments examples:

        # This is a valid single line comment.

        # This is valid multi
        # line comments.
        # Yup and valid.

        # `code` block.

        # "Wow", this is also allowed.

        # 'xox', also valid.

        # 9 is also valid.

        # Is this also valid?
        # - yes!
      """,
      params: [
        excluded_paths: "A list of paths to exclude",
        excluded_files: "A list of files to exclude",
        non_capitalized_sentence: "Regex to match non-capitalized sentence.",
        capitalized_sentence_without_end: "Regex to match capitalized sentence without end.",
        comment_sentence_without_end: "Regex to match any comment sentence without end."
      ]
    ]

  @doc false
  def run(source_file, params \\ []) do
    excluded_paths = Params.get(params, :excluded_paths, __MODULE__)
    excluded_files = Params.get(params, :excluded_files, __MODULE__)

    if Enum.member?(excluded_files, source_file.filename) or
         String.starts_with?(source_file.filename, excluded_paths) do
      []
    else
      lines = SourceFile.lines(source_file)

      issue_meta = IssueMeta.for(source_file, params)

      {_, issues} = Enum.reduce(lines, {:single, []}, &process_line(&1, &2, issue_meta, params))

      issues
    end
  end

  defp process_line({line_no, line}, {comment_type, issues}, issue_meta, params) do
    case comment_type do
      :single -> process_single_comment(issues, issue_meta, line_no, line, params)
      :multiline -> process_multiline_comment(issues, issue_meta, line_no, line, params)
    end
  end

  defp process_single_comment(issues, issue_meta, line_no, line, params) do
    cond do
      run_regex(line, :capitalized_sentence_without_end, params) != nil ->
        {:multiline, issues}

      run_regex(line, :non_capitalized_sentence, params) != nil ->
        [match | _] = run_regex(line, :non_capitalized_sentence, params)
        {:single, add_to_issues(issues, issue_meta, line_no, match)}

      true ->
        {:single, issues}
    end
  end

  defp process_multiline_comment(issues, _issue_meta, _line_no, line, params) do
    case run_regex(line, :comment_sentence_without_end, params) do
      nil -> {:single, issues}
      _ -> {:multiline, issues}
    end
  end

  defp add_to_issues(issues, issue_meta, line_no, match) do
    match
    |> build_message()
    |> issue_for(issue_meta, line_no, match)
    |> List.wrap()
    |> Kernel.++(issues)
  end

  defp run_regex(line, regex_identifier, params) do
    params
    |> Params.get(regex_identifier, __MODULE__)
    |> Regex.run(line)
  end

  defp build_message(match),
    do:
      "Non-capitalized beginning of comment found: \"#{match}\". Comments longer than one word must be capitalized"

  defp issue_for(message, issue_meta, line_no, trigger) do
    format_issue(issue_meta, message: message, line_no: line_no, trigger: trigger)
  end
end
