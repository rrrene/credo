defmodule Credo.CLI.Command.Categories.CategoriesOutput do
  alias Credo.CLI.Output.UI

  alias Credo.CLI.Command.Categories.Output.Default

  def print_before_info(source_files, exec) do
    output_mod(exec).print_before_info(source_files, exec)
  end

  def print_after_info(source_file, exec, line_no, column) do
    output_mod(exec).print_after_info(source_file, exec, line_no, column)
  end

  defp output_mod(_exec), do: Default
end
