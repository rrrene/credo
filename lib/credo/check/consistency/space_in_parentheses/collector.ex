defmodule Credo.Check.Consistency.SpaceInParentheses.Collector do
  use Credo.Check.Consistency.Collector

  alias Credo.Check.CodeHelper
  alias Credo.Code

  @regex [
    with_space: ~r/[^\?]([\{\[\(]\s+\S|\S\s+[\)\]\}])/,
    without_space: ~r/[^\?]([\{\[\(]\S|\S[\)\]\}])/
  ]

  def collect_matches(source_file, _params) do
    source_file
    |> CodeHelper.clean_charlists_strings_sigils_and_comments
    |> Code.to_lines
    |> Enum.reduce(%{}, &spaces/2)
  end

  def find_locations_not_matching(expected, source_file) do
    actual = case expected do
      :with_space -> :without_space
      :without_space -> :with_space
    end

    source_file
    |> CodeHelper.clean_charlists_strings_sigils_and_comments
    |> Code.to_lines
    |> List.foldr([], &locate(actual, &1, &2))
  end

  defp spaces({_line_no, line}, acc) do
    Enum.reduce(@regex, acc, fn({kind_of_space, regex}, space_map) ->
      if Regex.match?(regex, line) do
        Map.update(space_map, kind_of_space, 1, &(&1 + 1))
      else
        space_map
      end
    end)
  end

  defp locate(kind_of_space, {line_no, line}, locations) do
    case Regex.run(@regex[kind_of_space], line) do
      nil ->
        locations
      match ->
        [[trigger: Enum.at(match, 1), line_no: line_no] | locations]
    end
  end
end
