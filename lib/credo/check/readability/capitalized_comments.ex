defmodule Credo.Check.Readability.CapitalizedComments do
  @moduledoc false

  use Credo.Check,
    category: :readability,
    tags: [:experimental],
    param_defaults: [
      rules: []
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
        rules: ""
      ]
    ]

  @doc false
  def run(source_file, params \\ []) do
    lines =
      source_file
      |> Credo.Code.clean_charlists_strings_and_sigils()
      |> Credo.Code.to_lines()

    issue_meta = IssueMeta.for(source_file, params)
    rules = Params.get(params, :rules, __MODULE__)

    {_, all_comments} = Enum.reduce(lines, {[], []}, &extract_comment_blocks/2)

    all_comments =
      Enum.map(all_comments, fn
        [] ->
          nil

        comments ->
          {first_line_no, _} = Enum.at(comments, 0)

          comment =
            Enum.map_join(comments, "\n", fn {_line_no, line} ->
              String.replace(line, ~r/^(\s*#\s?)/, "")
            end)

          {first_line_no, comment}
      end)
      |> Enum.reject(&is_nil/1)

    IO.inspect(all_comments)

    all_comments
    |> Enum.map(fn {first_line_no, line} ->
      Enum.find_value(rules, fn rule ->
        issue_or_nil(first_line_no, line, rule, issue_meta)
      end)
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp extract_comment_blocks({line_no, line}, {current_comments, all_comments}) do
    if String.match?(line, ~r/^\s*#/) do
      previous_line_no = line_no - 1

      case List.last(current_comments) do
        {^previous_line_no, _} -> {current_comments ++ [{line_no, line}], all_comments}
        _ -> {[{line_no, line}], all_comments ++ [current_comments]}
      end
    else
      {current_comments, all_comments}
    end
  end

  defp issue_or_nil(first_line_no, line, rule, issue_meta) do
    if_match_given = rule[:if_match] && String.match?(line, rule[:if_match])
    unless_match_given = rule[:unless_match] && !String.match?(line, rule[:unless_match])

    if if_match_given || unless_match_given do
      case Regex.run(rule[:require_match], line) do
        nil ->
          issue_for(issue_meta, first_line_no, line, rule[:message])

        _value ->
          nil
      end
    end
  end

  defp issue_for(issue_meta, line_no, trigger, message) do
    format_issue(
      issue_meta,
      message: "Comment does not match required format (#{message})",
      line_no: line_no,
      trigger: trigger
    )
  end
end
