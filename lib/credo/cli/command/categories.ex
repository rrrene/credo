defmodule Credo.CLI.Command.Categories do
  use Credo.CLI.Command

  @shortdoc "Show and explain all issue categories"

  def run(_args, _config) do
    output_mod().print
    :ok
  end

  defp output_mod do
    Credo.CLI.Output.Categories
  end
end
