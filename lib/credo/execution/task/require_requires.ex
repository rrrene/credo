defmodule Credo.Execution.Task.RequireRequires do
  @moduledoc false

  use Credo.Execution.Task

  alias Credo.Sources

  def call(%Execution{} = exec, _opts) do
    exec
    |> Execution.get_config(:requires)
    |> Sources.find()
    |> Enum.each(&Code.require_file/1)

    exec
  end
end
