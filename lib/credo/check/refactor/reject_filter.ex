defmodule Credo.Check.Refactor.RejectFilter do
  use Credo.Check,
    id: "EX4025",
    tags: [:controversial],
    explanations: [
      check: """
      One `Enum.filter/2` (or corresponding `Map` and `Keyword` calls) is more efficient than `Enum.reject/2 |> Enum.filter/2`.

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
  alias Credo.Check.Refactor.MapHelpers
  alias Credo.Check.Refactor.KeywordHelpers

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    trigger = "|>"

    Enum.flat_map(
      [
        {&EnumHelpers.traverse/8, "Enum"},
        {&MapHelpers.traverse/8, "Map"},
        {&KeywordHelpers.traverse/8, "Keyword"}
      ],
      fn {traverse, module} ->
        message =
          "One `#{module}.reject/2` is more efficient than `#{module}.reject/2 |> #{module}.filter/2`"

        Credo.Code.prewalk(
          source_file,
          fn ast, issues ->
            traverse.(ast, issues, issue_meta, message, trigger, :reject, :filter, __MODULE__)
          end
        )
      end
    )
  end
end
