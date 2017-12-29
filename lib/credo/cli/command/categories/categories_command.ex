defmodule Credo.CLI.Command.Categories.CategoriesCommand do
  use Credo.CLI.Command

  alias Credo.CLI.Command.Categories.CategoriesOutput

  @shortdoc "Show and explain all issue categories"
  @moduledoc @shortdoc

  @doc false
  def call(exec, _opts) do
    CategoriesOutput.print_categories(exec)

    exec
  end
end
