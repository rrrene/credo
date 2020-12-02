defmodule Credo.Execution.Task.ParseOptions do
  @moduledoc false

  use Credo.Execution.Task

  alias Credo.CLI.Options
  alias Credo.CLI.Output.UI
  alias Credo.Execution

  def call(exec, _opts) do
    command_names = Execution.get_valid_command_names(exec)

    given_command_name =
      if exec.cli_options do
        exec.cli_options.command
      end

    cli_options =
      Options.parse(
        exec.argv,
        File.cwd!(),
        command_names,
        given_command_name,
        [UI.edge()],
        exec.cli_switches,
        exec.cli_aliases
      )

    %Execution{exec | cli_options: cli_options}
  end
end
