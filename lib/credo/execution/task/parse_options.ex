defmodule Credo.Execution.Task.ParseOptions do
  use Credo.Execution.Task

  alias Credo.CLI.Options
  alias Credo.CLI.Output.UI
  alias Credo.Service.Commands

  def call(exec, _opts) do
    cli_options = Options.parse(exec.argv, File.cwd!(), Commands.names(), [UI.edge()])

    %Execution{exec | cli_options: cli_options}
  end
end
