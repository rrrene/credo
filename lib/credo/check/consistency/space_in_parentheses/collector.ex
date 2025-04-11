defmodule Credo.Check.Consistency.SpaceInParentheses.Collector do
  @moduledoc false

  use Credo.Check.Consistency.Collector

  def collect_matches(source_file, _params) do
    regexes = all_regexes()

    source_file
    |> Credo.Code.clean_charlists_strings_sigils_and_comments("")
    |> Credo.Code.to_lines()
    |> Enum.reduce(%{}, &spaces(&1, &2, regexes))
  end

  def find_locations_not_matching(expected, source_file, allow_empty_enums) do
    regexes = all_regexes()

    actual =
      case expected do
        :with_space when allow_empty_enums == true -> :without_space_allow_empty_enums
        :with_space -> :without_space
        :without_space -> :with_space
      end

    source_file
    |> Credo.Code.clean_charlists_strings_sigils_and_comments("")
    |> Credo.Code.to_lines()
    |> List.foldr([], &locate(actual, &1, &2, regexes))
  end

  defp spaces({_line_no, line}, acc, regexes) do
    Enum.reduce(regexes, acc, fn {kind_of_space, regex}, space_map ->
      if Regex.match?(regex, line) do
        Map.update(space_map, kind_of_space, 1, &(&1 + 1))
      else
        space_map
      end
    end)
  end

  defp locate(kind_of_space, {line_no, line}, locations, regexes) do
    case Regex.run(regexes[kind_of_space], line) do
      nil ->
        locations

      match ->
        [[trigger: Enum.at(match, 1), line_no: line_no] | locations]
    end
  end

  # moved to private function due to deprecation of regexes
  # in module attributes in Elixir 1.19
  defp all_regexes do
    [
      with_space: ~r/[^\?]([\{\[\(]\s+\S|\S\s+[\)\]\}]])/,
      without_space: ~r/[^\?]([\{\[\(]\S|\S[\)\]\}])/,
      without_space_allow_empty_enums: ~r/[^\?](?!\{\}|\[\])([\{\[\(]\S|\S[\)\]\}])/
    ]
  end
end
