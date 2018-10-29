defmodule Credo.CLI.Command.Categories.CategoriesCommand do
  @moduledoc false

  @shortdoc "Show and explain all issue categories"

  use Credo.CLI.Command

  alias Credo.CLI.Command.Categories.CategoriesOutput

  @doc false
  def call(exec, _opts) do
    CategoriesOutput.print_categories(exec)

    exec
  end
end
