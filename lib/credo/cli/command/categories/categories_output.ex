defmodule Credo.CLI.Command.Categories.CategoriesOutput do
  @moduledoc false

  alias Credo.CLI.Command.Categories.Output.Default

  def print_categories(_exec) do
    Default.print_categories()
  end
end
