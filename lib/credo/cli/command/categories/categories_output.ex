defmodule Credo.CLI.Command.Categories.CategoriesOutput do
  alias Credo.CLI.Command.Categories.Output.Default

  def print_categories(_exec) do
    Default.print_categories()
  end
end
