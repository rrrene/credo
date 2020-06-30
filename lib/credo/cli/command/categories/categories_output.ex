defmodule Credo.CLI.Command.Categories.CategoriesOutput do
  @moduledoc false

  use Credo.CLI.Output.FormatDelegator,
    default: Credo.CLI.Command.Categories.Output.Default,
    json: Credo.CLI.Command.Categories.Output.Json

  def print_categories(exec, categories) do
    format_mod = format_mod(exec)

    format_mod.print(exec, categories)
  end
end
