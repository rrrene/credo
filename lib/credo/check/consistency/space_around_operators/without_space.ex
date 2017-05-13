defmodule Credo.Check.Consistency.SpaceAroundOperators.WithoutSpace do
  use Credo.Check.CodePattern

  alias Credo.Check.Consistency.SpaceAroundOperators.SpaceHelper

  def property_value, do: :without_space

  def property_value_for(source_file, _params) do
    property_values_for(source_file)
  end

  defp property_values_for(source_file) do
    source_file
    |> Credo.Code.to_tokens
    |> check_tokens([])
    |> Enum.uniq
    |> Enum.map(&to_property_values(&1, source_file))
  end

  defp to_property_values({{line_no, column, _}, :/ = trigger}, source_file) do
    line = SourceFile.line_at(source_file, line_no)

    function_capture? =
      ~r/(\&[a-zA-Z0-9\.\_\?\!]+\/\d+)/     # pattern to detect &Mod.fun/4
      |> Regex.run(line, return: :index)
      |> List.wrap
      |> Enum.any?(fn({start_index, _end_index}) ->
          String.slice(line, start_index..column+1) =~ ~r/^\S+$/
        end)

    unless function_capture? do
      to_property_values(line_no, column, trigger, source_file)
    end
  end
  defp to_property_values({{line_no, column, _}, trigger}, source_file) do
    to_property_values(line_no, column, trigger, source_file)
  end
  defp to_property_values(line_no, column, trigger, source_file) do
    PropertyValue.for(property_value(), filename: source_file.filename, line_no: line_no, column: column, trigger: trigger)
  end

  defp check_tokens([], acc), do: acc
  defp check_tokens([prev | t], acc) do
    current = List.first(t)
    next = Enum.at(t, 1)

    acc =
      if SpaceHelper.operator?(current) do
        acc ++ collect_tokens(prev, current, next)
      else
        acc
      end

    check_tokens(t, acc)
  end

  def collect_tokens(prev, operator, next) do
    collect_before(prev, operator, next) ++ collect_after(prev, operator, next)
  end

  defp collect_before(prev, operator, next) do
    if SpaceHelper.no_space_between?(prev, operator) && !SpaceHelper.usually_no_space_before?(prev, operator, next) do
      [SpaceHelper.trigger_token(operator)]
    else
      []
    end
  end

  defp collect_after(prev, operator, next) do
    if SpaceHelper.no_space_between?(operator, next) && !SpaceHelper.usually_no_space_after?(prev, operator, next) do
      case next do
        {:eol, _} ->
          []
        _ ->
          [SpaceHelper.trigger_token(operator)]
      end
    else
      []
    end
  end
end
