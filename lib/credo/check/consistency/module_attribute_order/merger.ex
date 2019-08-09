defmodule Credo.Check.Consistency.ModuleAttributeOrder.Merger do
  # From: https://github.com/christopheradams/elixir_style_guide#module-attribute-ordering
  # Used as fallback if the codebase has insufficient examples
  @styleguide_order [
    :moduledoc,
    :behaviour,
    :use,
    :import,
    :alias,
    :require,
    :module_attribute,
    :defstruct,
    :type,
    :callback,
    :macrocallback,
    :optional_callbacks
  ]

  def merge_frequencies(%{} = frequencies) do
    frequencies
    |> Enum.sort_by(fn {attributes, frequency} -> {frequency, length(attributes)} end, &>=/2)
    |> merge_frequencies()
    |> Map.new()
  end

  def merge_frequencies(frequencies) when is_list(frequencies) do
    do_merge_frequencies(frequencies, [])
  end

  defp do_merge_frequencies([], merged), do: merged
  defp do_merge_frequencies([occurrence], merged), do: [occurrence | merged]

  defp do_merge_frequencies([occurrence | rest], merged) do
    {merged_occurrence, unmergable} =
      merge_occurrence(occurrence,
        with: rest,
        already_merged: merged
      )

    do_merge_frequencies(unmergable, [merged_occurrence | merged])
  end

  defp merge_occurrence(to_merge, with: maybe_mergable, already_merged: already_merged) do
    reference = already_merged ++ maybe_mergable

    {merged, unmergable} =
      Enum.reduce(
        maybe_mergable,
        {to_merge, []},
        fn to_merge, {merged, unmergable} ->
          case try_to_merge_occurrences(merged, to_merge, reference: reference) do
            {:ok, merged} ->
              {merged, unmergable}

            :error ->
              {merged, [to_merge | unmergable]}
          end
        end
      )

    {merged, Enum.reverse(unmergable)}
  end

  defp try_to_merge_occurrences(merged, to_merge, reference: reference) do
    try_to_merge_occurrences(merged, to_merge, order: [], reference: reference)
  end

  defp try_to_merge_occurrences(merged, to_merge, order: order, reference: reference) do
    {:ok, merge_occurrences!(merged, to_merge, order)}
  catch
    :conflict ->
      :error

    {:unclear, unclear} ->
      order =
        case determine_order_from(unclear, reference) do
          {ordered, [] = _unclear} ->
            ordered

          {_ordered, _unclear} ->
            Enum.filter(@styleguide_order, &(&1 in unclear))
        end

      try_to_merge_occurrences(merged, to_merge, order: order, reference: reference)
  end

  defp merge_occurrences!(
         {attributes, frequency},
         {attributes_to_merge, frequency_to_merge},
         order
       ) do
    {
      merge_attributes!(attributes, attributes_to_merge, order),
      frequency + frequency_to_merge
    }
  end

  defp merge_attributes!(attributes, attributes, _order), do: attributes
  defp merge_attributes!([], attributes, _order), do: attributes
  defp merge_attributes!(attributes, [], _order), do: attributes

  defp merge_attributes!([attribute | rest], [attribute | other_rest], order) do
    [attribute | merge_attributes!(rest, other_rest, order)]
  end

  defp merge_attributes!([attribute | rest], [other_attribute | other_rest], order) do
    case {attribute in other_rest, other_attribute in rest} do
      {true, false} ->
        [other_attribute | merge_attributes!([attribute | rest], other_rest, order)]

      {false, true} ->
        [attribute | merge_attributes!(rest, [other_attribute | other_rest], order)]

      {true, true} ->
        throw(:conflict)

      {false, false} ->
        order
        |> Enum.filter(&(&1 in [attribute, other_attribute]))
        |> case do
          [_, _] = order ->
            order ++ merge_attributes!(rest, other_rest, order)

          _not_contained_in_order ->
            throw({:unclear, [attribute, other_attribute] ++ order})
        end
    end
  end

  defp determine_order_from({_ordered, []} = ordered, _attributes), do: ordered

  defp determine_order_from(unclear, attributes) when is_list(unclear) do
    determine_order_from({[], unclear}, attributes)
  end

  defp determine_order_from(ordered_and_unclear, [{_attributes, _frequency} | _] = occurrences) do
    determine_order_from(
      ordered_and_unclear,
      Enum.map(occurrences, fn {attributes, _} -> attributes end)
    )
  end

  defp determine_order_from(ordered_and_unclear, [attributes | _] = all_attributes)
       when is_list(attributes) do
    Enum.reduce(all_attributes, ordered_and_unclear, fn attributes, ordered_and_unclear ->
      determine_order_from(ordered_and_unclear, attributes)
    end)
  end

  defp determine_order_from({ordered, unclear}, attributes) do
    new_ordered =
      unclear
      |> Enum.filter(&(&1 in attributes))
      |> Enum.sort_by(&Enum.find_index(attributes, fn attribute -> attribute == &1 end))

    {ordered ++ new_ordered, unclear -- new_ordered}
  end
end
