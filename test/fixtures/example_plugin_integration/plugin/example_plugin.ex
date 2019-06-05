defmodule ExamplePlugin do
  @config_file File.read!(Path.join(__DIR__, ".credo.exs"))

  import Credo.Plugin

  def init(exec) do
    exec
    |> register_default_config(@config_file)
    |> register_command("example", ExamplePlugin.ExampleCommand)
    |> register_cli_switch(:world, :string, :W, fn switch_value ->
      {:world, String.upcase(switch_value)}
    end)
    |> prepend_task(:set_default_command, ExamplePlugin.SetExampleAsDefaultCommand)
  end
end

defmodule ExamplePlugin.ExampleCommand do
  @moduledoc false

  alias Credo.Execution

  def call(exec, _) do
    world = Execution.get_plugin_param(exec, ExamplePlugin, :world)

    Execution.put_assign(exec, "example_plugin.hello", "Hello #{world}!")
  end
end

defmodule ExamplePlugin.SetExampleAsDefaultCommand do
  use Credo.Execution.Task

  alias Credo.CLI.Options

  def call(exec, _opts) do
    set_command(exec, exec.cli_options.command || "example")
  end

  defp set_command(exec, command) do
    %Execution{exec | cli_options: %Options{exec.cli_options | command: command}}
  end
end
