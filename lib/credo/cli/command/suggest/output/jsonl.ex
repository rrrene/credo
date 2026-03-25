defmodule Credo.CLI.Command.Suggest.Output.Jsonl do
  @moduledoc false

  alias Credo.CLI.Output.Formatter.JSON
  alias Credo.Execution

  def print_before_info(_source_files, _exec), do: nil

  def print_after_info(_source_files, exec, _time_load, _time_run) do
    exec
    |> Execution.get_issues()
    |> Enum.each(fn issue ->
      issue
      |> JSON.issue_to_json()
      |> JSON.print_term()
    end)
  end
end
