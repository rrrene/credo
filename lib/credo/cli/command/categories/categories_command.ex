defmodule Credo.CLI.Command.Categories.CategoriesCommand do
  use Credo.CLI.Command

  @shortdoc "Show and explain all issue categories"

  @doc false
  def call(exec, _opts) do
    output_mod().print

    exec
  end

  defp output_mod do
    Credo.CLI.Output.Categories
  end
end
