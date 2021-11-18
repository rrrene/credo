defmodule Credo.Check.Refactor.RejectReject do
  use Credo.Check,
    explanations: [
      check: """
      One `Enum.reject/2` is more efficient than `Enum.reject/2 |> Enum.reject/2`.

      This should be refactored:

          ["a", "b", "c"]
          |> Enum.reject(&String.contains?(&1, "x"))
          |> Enum.reject(&String.contains?(&1, "a"))

      to look like this:

          Enum.reject(["a", "b", "c"], fn letter ->
            String.contains?(letter, "x") || String.contains?(letter, "a")
          end)

      The reason for this is performance, because the two separate calls
      to `Enum.reject/2` require two iterations whereas doing the
      functions in the single `Enum.reject/2` only requires one.
      """
    ]

  alias Credo.Check.Refactor.EnumHelpers

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    message = "One `Enum.reject/2` is more efficient than `Enum.reject/2 |> Enum.reject/2`"
    trigger = "|>"

    Credo.Code.prewalk(
      source_file,
      &EnumHelpers.traverse(&1, &2, issue_meta, message, trigger, :reject, :reject, __MODULE__)
    )
  end
end
