defmodule Credo.Check.Refactor.MapMap do
  use Credo.Check,
    explanations: [
      check: """
      One `Enum.map/2` is more efficient than `Enum.map/2 |> Enum.map/2`.

      This should be refactored:

          [:a, :b, :c]
          |> Enum.map(&inspect/1)
          |> Enum.map(&String.upcase/1)

      to look like this:

          Enum.map([:a, :b, :c], fn letter ->
            letter
            |> inspect()
            |> String.upcase()
          end)

      The reason for this is performance, because the two separate calls
      to `Enum.map/2` require two iterations whereas doing the functions
      in the single `Enum.map/2` only requires one.
      """
    ]

  alias Credo.Check.Refactor.EnumHelpers

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    message = "One `Enum.map/2` is more efficient than `Enum.map/2 |> Enum.map/2`"
    trigger = "|>"

    Credo.Code.prewalk(
      source_file,
      &EnumHelpers.traverse(&1, &2, issue_meta, message, trigger, :map, :map, __MODULE__)
    )
  end
end
