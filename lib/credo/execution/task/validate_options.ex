defmodule Credo.Execution.Task.ValidateOptions do
  @moduledoc false

  use Credo.Execution.Task

  alias Credo.CLI.Options
  alias Credo.CLI.Output.UI

  @exit_status Credo.CLI.ExitStatus.config_loaded_but_invalid()

  def call(exec, _opts) do
    case exec.cli_options do
      %Options{unknown_args: [], unknown_switches: []} ->
        exec

      _ ->
        Execution.halt(exec)
    end
  end

  @spec error(Credo.Execution.t(), keyword()) :: no_return
  def error(exec, _opts) do
    UI.use_colors(exec)

    Enum.each(exec.cli_options.unknown_args, &print_argument(exec, &1))
    Enum.each(exec.cli_options.unknown_switches, &print_switch(exec, &1))

    put_exit_status(exec, @exit_status)
  end

  defp print_argument(exec, name) do
    UI.warn([
      :red,
      "** (credo) Unknown argument for `#{exec.cli_options.command}` command: #{name}"
    ])
  end

  defp print_switch(exec, {name, _value}), do: print_switch(exec, name)

  defp print_switch(exec, name) do
    UI.warn([:red, "** (credo) Unknown switch for `#{exec.cli_options.command}` command: #{name}"])
  end
end
