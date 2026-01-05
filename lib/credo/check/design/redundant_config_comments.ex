defmodule Credo.Check.Design.RedundantConfigComments do
  use Credo.Check,
    id: "EX2006",
    base_priority: :normal,
    param_defaults: [],
    explanations: [
      check: """
      Config comments are sometimes left unchecked and become redundant.

      This can happen because a comment ignored a check for a line that
      changed or where the check was disabled via the config.
      """
    ]

  alias Credo.Check.ConfigComment

  @impl true
  def scheduled_in_group, do: 10

  @doc false
  def run_on_all_source_files(exec, source_files, params) do
    existing_issues = Execution.get_issues(exec)

    new_issues =
      existing_issues
      |> redundant_config_comments(exec)
      |> Enum.map(fn {filename, config_comment} ->
        source_file = Enum.find(source_files, &(&1.filename == filename))
        issue_meta = IssueMeta.for(source_file, params)

        issue_for(issue_meta, config_comment.line_no)
      end)

    append_issues_and_timings(new_issues, exec)

    :ok
  end

  def redundant_config_comments(issues, exec) do
    config_comment_map = Execution.get_private(exec, :config_comment_map)

    Enum.flat_map(config_comment_map, fn {filename, config_comments} ->
      issues_for_file = Enum.filter(issues, &(&1.filename == filename))

      Enum.flat_map(config_comments, fn config_comment ->
        ignored =
          Enum.any?(issues_for_file, fn issue ->
            ConfigComment.ignores_issue?(config_comment, issue)
          end)

        if ignored do
          []
        else
          [{filename, config_comment}]
        end
      end)
    end)
  end

  defp issue_for(ctx, line_no) do
    format_issue(
      ctx,
      message: "This config comment does not ignore any issue.",
      trigger: "# credo:",
      line_no: line_no
    )
  end
end
