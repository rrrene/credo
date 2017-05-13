defmodule Credo.Check.Warning.UnusedPathOperation do
  @moduledoc """
  The result of a call to the Path module's functions has to be used.

  # TODO: write example

  Path operations never work on the variable you pass in, but return a new
  variable which has to be used somehow.
  """

  @explanation [check: @moduledoc]
  @checked_module :Path
  @funs_with_return_value nil

  alias Credo.Check.Warning.UnusedFunctionReturnHelper

  use Credo.Check, base_priority: :high

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    all_unused_calls =
      UnusedFunctionReturnHelper.find_unused_calls(source_file, params,
                                              [@checked_module], @funs_with_return_value)

    Enum.reduce(all_unused_calls, [], fn(invalid_call, issues) ->
      {_, meta, _} = invalid_call
      trigger =
        invalid_call
        |> Macro.to_string
        |> String.split("(")
        |> List.first

      issues ++ [issue_for(issue_meta, meta[:line], trigger)]
    end)
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue issue_meta,
      message: "There should be no unused return values for #{trigger}().",
      trigger: trigger,
      line_no: line_no
  end
end
