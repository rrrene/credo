defmodule Credo.Check.Consistency.SpaceAroundOperators.WithoutSpace do
  use Credo.Check.CodePattern

  alias Credo.Check.Consistency.SpaceAroundOperators.SpaceHelper

  def property_value, do: :without_space

  def property_value_for(source_file, _params) do
    property_values_for(source_file.source, source_file.filename)
  end

  defp property_values_for(source, filename) do
    source
    |> Credo.Code.to_tokens
    |> check_tokens([])
    |> Enum.uniq
    |> Enum.map(&to_property_values(&1, filename))
  end

  defp to_property_values({{line_no, column, _}, trigger}, filename) do
    property_value()
    |> PropertyValue.for(filename: filename, line_no: line_no, column: column, trigger: trigger)
  end

  defp check_tokens([], acc), do: acc
  defp check_tokens([prev | t], acc) do
    current = t |> List.first
    next = t |> Enum.at(1)

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
