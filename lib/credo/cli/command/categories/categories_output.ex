defmodule Credo.CLI.Command.Categories.CategoriesOutput do
  @moduledoc false

  def print_categories(exec, categories) do
    format_mod = format_mod(exec)

    format_mod.print(exec, categories)
  end

  defp format_mod(%{format: "json"}), do: Credo.CLI.Command.Categories.Output.Json
  defp format_mod(%{format: nil}), do: Credo.CLI.Command.Categories.Output.Default
end
