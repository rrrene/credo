defmodule Credo.Execution.Task.ParseOptions do
  @moduledoc false

  use Credo.Execution.Task

  alias Credo.CLI.Options
  alias Credo.CLI.Output.UI
  alias Credo.Execution

  def call(exec, _opts) do
    command_names = Execution.get_valid_command_names(exec)

    cli_options =
      Options.parse(
        exec.argv,
        File.cwd!(),
        command_names,
        [UI.edge()],
        exec.cli_switches,
        exec.cli_aliases
      )

    %Execution{exec | cli_options: cli_options}
  end
end
