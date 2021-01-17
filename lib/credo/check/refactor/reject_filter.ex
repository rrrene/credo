defmodule Credo.Check.Refactor.RejectFilter do
  use Credo.Check,
    tags: [:controversial],
    explanations: [
      check: """
      One `Enum.filter/2` is more efficient than `Enum.reject/2 |> Enum.filter/2`.

      This should be refactored:

          ["a", "b", "c"]
          |> Enum.reject(&String.contains?(&1, "x"))
          |> Enum.filter(&String.contains?(&1, "a"))

      to look like this:

          Enum.filter(["a", "b", "c"], fn letter ->
            !String.contains?(letter, "x") && String.contains?(letter, "a")
          end)

      The reason for this is performance, because the two calls to
      `Enum.reject/2` and `Enum.filter/2` require two iterations whereas
      doing the functions in the single `Enum.filter/2` only requires one.
      """
    ]

  alias Credo.Check.Refactor.EnumHelpers

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    message = "One `Enum.filter/2` is more efficient than `Enum.reject/2 |> Enum.filter/2`"
    trigger = "|>"

    Credo.Code.prewalk(
      source_file,
      &EnumHelpers.traverse(&1, &2, issue_meta, message, trigger, :reject, :filter, __MODULE__)
    )
  end
end
