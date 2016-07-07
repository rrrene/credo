defmodule Credo.Check.Consistency.SpaceInParentheses.WithSpace do
  use Credo.Check.CodePattern

  alias Credo.Check.CodeHelper
  alias Credo.Code

  @regex ~r/[^\?]([\{\[\(]\s+\S|\S\s+[\)\]\}])/

  def property_value, do: :with_space

  def property_value_for(source_file, _params) do
    source_file
    |> CodeHelper.clean_strings_sigils_and_comments
    |> Code.to_lines
    |> Enum.map(&property_value_for_line(&1, source_file.filename))
  end

  defp property_value_for_line({line_no, line}, filename) do
    results = Regex.run(@regex, line)
    if results do
      trigger = results |> Enum.at(1)
      property_value()
      |> PropertyValue.for(filename: filename, line_no: line_no, trigger: trigger)
    end
  end
end
