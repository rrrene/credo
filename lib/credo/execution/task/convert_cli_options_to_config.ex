defmodule Credo.Execution.Task.ConvertCLIOptionsToConfig do
  use Credo.Execution.Task

  alias Credo.ConfigBuilder
  alias Credo.Execution.Issues
  alias Credo.Execution.SourceFiles

  def call(exec, _opts) do
    exec.cli_options
    |> ConfigBuilder.parse
    |> start_servers()
  end

  defp start_servers(%Execution{} = exec) do
    exec
    |> SourceFiles.start_server
    |> Issues.start_server
  end
end
