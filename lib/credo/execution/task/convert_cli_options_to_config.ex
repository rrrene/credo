defmodule Credo.Execution.Task.ConvertCLIOptionsToConfig do
  use Credo.Execution.Task

  alias Credo.ConfigBuilder

  def call(exec, _opts) do
    exec
    |> ConfigBuilder.parse
    |> Execution.start_servers
  end
end
