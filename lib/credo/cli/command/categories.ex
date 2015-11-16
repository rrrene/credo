defmodule Credo.CLI.Command.Categories do
  def run(_dir, _config) do
    output_mod.print
    :ok
  end

  defp output_mod do
    Credo.CLI.Output.Categories
  end
end
