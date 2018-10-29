defmodule Credo.Execution.Task.UseColors do
  @moduledoc false

  use Credo.Execution.Task

  alias Credo.CLI.Output.UI

  def call(exec, _opts) do
    UI.use_colors(exec)
  end
end
