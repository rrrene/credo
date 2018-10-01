defmodule Credo.Check.Consistency.ModuleFilenames do
  @moduledoc """
  Filenames should reflect the name of the included module.

  Preferred
  1. lib/credo.ex matches `Credo`
  2. lib/credo/collector.ex matches `Credo.Collector`

  Not Preferred
  1. lib/credo.ex matches `Example`
  2. lib/credo/collector.ex matches `Example.Module`
  """

  @explanation [check: @moduledoc]

  @message "Filepath does not match module namespace"

  use Credo.Check, category: :consistency

  @doc false
  def run(%{filename: filename} = source_file, params \\ []) do
    module_parts = Credo.Code.prewalk(source_file, &find_module_name(&1, &2))

    if filepath_match?(filename, module_parts) do
      []
    else
      issue_meta = IssueMeta.for(source_file, params)

      human_readable_name =
        module_parts
        |> List.first()
        |> Enum.map(&to_string/1)
        |> Enum.join(".")

      [issue_for(issue_meta, 1, "defmodule #{human_readable_name} do")]
    end
  end

  defp extensionless(filename) do
    ext_length =
      filename
      |> Path.extname()
      |> String.length()

    String.slice(filename, 0..-(ext_length + 1))
  end

  defp filepath_match?(_filename, []) do
    # Files that lack modules, like `.exs`, should be allowed
    true
  end

  defp filepath_match?(filename, [head | rest]) when is_list(head) and length(rest) > 0 do
    filepath_match?(filename, List.last(rest))
  end

  defp filepath_match?(filename, module_parts) do
    parts =
      filename
      |> extensionless()
      |> String.split(~r/[.\/]/)

    if module_filepath(module_parts) -- parts == [] do
      true
    else
      false
    end
  end

  defp expected_path(module_name_parts) do
    case Enum.slice(module_name_parts, -2..-1) do
      [same, same] -> Enum.slice(module_name_parts, 0..-2)
      _ -> module_name_parts
    end
  end

  defp find_module_name({:defmodule, _, [{:__aliases__, _, module_name} | _]} = ast, accumulator) do
    {ast, [module_name | accumulator]}
  end

  defp find_module_name(ast, accumulator) do
    {ast, accumulator}
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(issue_meta, message: @message, line_no: line_no, trigger: trigger)
  end

  defp module_filepath([module_name_parts]) when is_list(module_name_parts) do
    module_filepath(module_name_parts)
  end

  defp module_filepath(module_name_parts) do
    module_name_parts
    |> Enum.map(&module_name_part/1)
    |> expected_path()
  end

  defp module_name_part(module_name) do
    module_name
    |> to_string()
    |> String.replace("IEx", "iex")
    |> String.replace(~r/(?<=[a-z])([A-Z])/, "_\\1")
    |> String.replace(~r/(?<=[A-Z])([A-Z][a-z])/, "_\\1")
    |> String.downcase()
  end
end
