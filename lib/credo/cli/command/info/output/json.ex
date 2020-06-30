defmodule Credo.CLI.Command.Info.Output.Json do
  @moduledoc false

  alias Credo.CLI.Output.Formatter.JSON
  alias Credo.Execution

  def print(%Execution{verbose: true}, info) do
    info
    |> verbose_info()
    |> JSON.print_map()
  end

  def print(_exec, info) do
    info
    |> basic_info()
    |> JSON.print_map()
  end

  defp basic_info(info) do
    %{
      system: info["system"]
    }
  end

  defp verbose_info(info) do
    info
  end
end
