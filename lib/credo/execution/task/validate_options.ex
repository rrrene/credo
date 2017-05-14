defmodule Credo.Execution.Task.ValidateOptions do
  use Credo.Execution.Task

  alias Credo.CLI.Options
  alias Credo.CLI.Output.UI

  def call(exec, _opts) do
    case exec.cli_options do
      %Options{unknown_args: [], unknown_switches: []} ->
        exec
      _ ->
        Execution.halt(exec)
    end
  end

  def error(exec, _opts) do
    UI.use_colors(exec)

    Enum.each(exec.cli_options.unknown_args, &print_argument/1)
    Enum.each(exec.cli_options.unknown_switches, &print_switch/1)

    System.halt(1)
  end

  defp print_argument(name) do
    UI.warn [:red, "Unknown argument: #{name}"]
  end

  defp print_switch({name, _value}), do: print_switch(name)
  defp print_switch(name) do
    UI.warn [:red, "Unknown switch: #{name}"]
  end
end
