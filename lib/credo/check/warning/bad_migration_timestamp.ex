defmodule Credo.Check.Warning.BadMigrationTimestamp do
  use Credo.Check,
    base_priority: :high,
    param_defaults: [included: ["priv/repo/migrations/*.exs"]],
    explanations: [
      check: """
      If a migration file name is hand edited it is possible to have an aberrant timestamp
      which will always be applied last no matter how many later migrations are added

      This check ensures that migration files do not have such timestamps.
      """
    ]

  @test_files_containing_timestamp ~r/(?<timestamp>\d{14}\d*).*.exs$/

  alias Credo.SourceFile

  @doc false
  def run(%SourceFile{filename: filename} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    if map = Regex.named_captures(@test_files_containing_timestamp, filename) do
      timestamp = map["timestamp"]
      {ts_year, ""} = timestamp |> binary_part(0, 4) |> Integer.parse()
      {ts_month, ""} = timestamp |> binary_part(4, 2) |> Integer.parse()
      ts_length = String.length(timestamp)
      %{year: year, month: month} = Date.utc_today

      # to account for timezone/dateline differences, we should tolerate 1 "year" or 1 "month" of difference
      # but more than that must be an error...  could do more fine grained checking, but coarse
      # check seems good enough for detecting most user errors.
      if ts_length > 14 or ts_year > year + 1 or (ts_year == year and ts_month > month + 1) do
        issue_meta
        |> issue_for()
        |> List.wrap()
      else
        []
      end
    else
      []
    end
  end

  defp issue_for(issue_meta) do
    format_issue(
      issue_meta,
      message: "Migration timestamps should be in past"
    )
  end
end
