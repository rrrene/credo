defmodule Credo.CLI.Command.Categories.Output.Json do
  @moduledoc false

  alias Credo.CLI.Output.Formatter.JSON

  def print(_exec, categories) do
    JSON.print_map(%{categories: categories})
  end
end
