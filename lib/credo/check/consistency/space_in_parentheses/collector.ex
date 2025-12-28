defmodule Credo.Check.Consistency.SpaceInParentheses.Collector do
  @moduledoc false
  use Credo.Check.Consistency.Collector

  @bracket_patterns ["(", ")", "[", "]", "{", "}"]
  @bracket_space_patterns ["( ", "[ ", "{ ", " )", " ]", " }"]

  # Regexes include a [^\?] guard to avoid matching codepoint literals like ?(, ?), etc.
  @regex_with_space ~r/[^\?]([\{\[\(]\s+\S|\S\s+[\)\]\}])/
  @regex_without_space ~r/[^\?]([\{\[\(]\S|\S[\)\]\}])/
  @regex_without_space_allow_empty_enums ~r/[^\?](?!\{\}|\[\])([\{\[\(]\S|\S[\)\]\}])/

  def collect_matches(source_file, _params) do
    lines = lines(source_file)

    Enum.reduce(lines, %{}, fn {_line_no, line}, counts ->
      if has_any_bracket?(line) do
        counts
        |> count_with_space(line)
        |> count_without_space(line)
      else
        counts
      end
    end)
  end

  def find_locations_not_matching(expected, source_file, allow_empty_enums) do
    lines = lines(source_file)

    match_type =
      case expected do
        :with_space when allow_empty_enums == true -> :without_space_allow_empty_enums
        :with_space -> :without_space
        :without_space -> :with_space
      end

    Enum.reduce(lines, [], fn {line_no, line}, acc ->
      if has_any_bracket?(line) do
        case get_trigger(match_type, line) do
          nil -> acc
          trigger -> [[trigger: trigger, line_no: line_no] | acc]
        end
      else
        acc
      end
    end)
  end

  defp count_with_space(counts, line) do
    if has_obvious_space_around_bracket?(line) and Regex.match?(@regex_with_space, line) do
      Map.update(counts, :with_space, 1, &(&1 + 1))
    else
      counts
    end
  end

  defp count_without_space(counts, line) do
    if Regex.match?(@regex_without_space, line) do
      counts = Map.update(counts, :without_space, 1, &(&1 + 1))

      if Regex.match?(@regex_without_space_allow_empty_enums, line) do
        Map.update(counts, :without_space_allow_empty_enums, 1, &(&1 + 1))
      else
        counts
      end
    else
      counts
    end
  end

  defp get_trigger(:with_space, line) do
    if has_obvious_space_around_bracket?(line) do
      run_regex(@regex_with_space, line)
    end
  end

  defp get_trigger(:without_space, line) do
    run_regex(@regex_without_space, line)
  end

  defp get_trigger(:without_space_allow_empty_enums, line) do
    run_regex(@regex_without_space_allow_empty_enums, line)
  end

  defp run_regex(regex, line) do
    case Regex.run(regex, line, return: :index) do
      [_, {start, len} | _] -> binary_part(line, start, len)
      _ -> nil
    end
  end

  defp lines(source_file) do
    source_file
    |> Credo.Code.clean_charlists_strings_sigils_and_comments("")
    |> Credo.Code.to_lines()
  end

  # Quick prefilter: bail if line has no brackets at all
  defp has_any_bracket?(line) do
    :binary.match(line, @bracket_patterns) != :nomatch
  end

  # Quick prefilter specifically for the "with_space" case to avoid any regex if
  # there's no obvious whitespace around brackets.
  defp has_obvious_space_around_bracket?(line) do
    # Space after open or before closing bracket
    :binary.match(line, @bracket_space_patterns) != :nomatch
  end
end
