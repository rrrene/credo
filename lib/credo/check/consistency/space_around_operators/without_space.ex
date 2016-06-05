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
    property_value
    |> PropertyValue.for(filename: filename, line_no: line_no, column: column, trigger: trigger)
  end

  defp check_tokens([], acc), do: List.flatten(acc)
  defp check_tokens([prev | t], acc) do
    destructure [current, next], t
    if SpaceHelper.operator?(current) do
      check_tokens(t, [acc, trigger_tokens_before(prev, current, next),
                            trigger_tokens_after(prev, current, next)])
    else
      check_tokens(t, acc)
    end
  end

  defp trigger_tokens_before(prev, operator, next) do
    if SpaceHelper.no_space_between?(prev, operator) and not SpaceHelper.usually_no_space_before?(prev, operator, next) do
      [SpaceHelper.trigger_token(operator)]
    else
      []
    end
  end

  defp trigger_tokens_after(prev, operator, next) do
    if not match?({:eol, _}, next) and SpaceHelper.no_space_between?(operator, next) and not SpaceHelper.usually_no_space_after?(prev, operator, next) do
      [SpaceHelper.trigger_token(operator)]
    else
      []
    end
  end
end
