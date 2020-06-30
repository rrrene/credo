defmodule Credo.CLI.Command.Explain.Output.Json do
  @moduledoc false

  alias Credo.CLI.Output.Formatter.JSON

  def print_before_info(_source_files, _exec), do: nil

  def print_after_info(explanations, _exec, _, _) do
    JSON.print_map(%{explanations: Enum.map(explanations, &cast_to_json/1)})
  end

  defp cast_to_json(%{line_no: _line_no} = explanation) do
    related_code = Enum.map(explanation.related_code, &Tuple.to_list/1)

    explanation
    |> Map.put(:related_code, related_code)
  end

  defp cast_to_json(explanation), do: explanation
end
