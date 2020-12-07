defmodule Credo.Execution.Task.ConvertCLIOptionsToConfig do
  @moduledoc false

  use Credo.Execution.Task

  alias Credo.ConfigBuilder
  alias Credo.CLI.Output.UI

  def call(exec, _opts) do
    exec
    |> ConfigBuilder.parse()
    |> halt_on_error(exec)
  end

  def halt_on_error({:error, error}, exec) do
    Execution.halt(exec, error)
  end

  def halt_on_error(exec, _) do
    exec
  end

  def error(exec, _opts) do
    exec
    |> Execution.get_halt_message()
    |> puts_error_message()

    exec
  end

  defp puts_error_message({:badconfig, filename, line_no, description, trigger})
       when not is_nil(filename) do
    lines =
      filename
      |> File.read!()
      |> Credo.Code.to_lines()
      |> Enum.filter(fn {line_no2, _line} ->
        line_no2 >= line_no - 2 and line_no2 <= line_no + 2
      end)

    UI.warn([:red, "** (config) Error while loading config file!"])
    UI.warn("")

    UI.warn([:cyan, "  file: ", :reset, filename])
    UI.warn([:cyan, "  line: ", :reset, "#{line_no}"])
    UI.warn("")

    UI.warn(["  ", description, :reset, :cyan, :bright, trigger])

    UI.warn("")

    Enum.each(lines, fn {line_no2, line} ->
      color = color_list(line_no, line_no2)

      UI.warn([color, String.pad_leading("#{line_no2}", 5), :reset, "  ", color, line])
    end)

    UI.warn("")
  end

  defp puts_error_message({:notfound, message}) do
    UI.warn([:red, "** (config) #{message}"])
    UI.warn("")
  end

  defp puts_error_message({:config_name_not_found, message}) do
    UI.warn([:red, "** (config) #{message}"])
    UI.warn("")
  end

  defp puts_error_message(error) do
    IO.warn("Execution halted during #{__MODULE__}! Unrecognized error: #{inspect(error)}")
  end

  defp color_list(line_no, line_no2) when line_no == line_no2, do: [:bright, :cyan]
  defp color_list(_, _), do: [:faint]
end
