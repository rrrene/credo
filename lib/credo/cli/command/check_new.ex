defmodule Credo.CLI.Command.CheckNew do
  use Credo.CLI.Command

  @shortdoc "Create a new custom check"

  @check_template_filename ".template.check.ex"
  @default_check_template_file File.read!(@check_template_filename)

  def run(_args, _config) do
    # TODO: print warning for missing filename
    # TODO: get filename from args
    # TODO: print info how to add it to .credo.exs
    #
    #       Add this to your `.credo.exs`:
    #
    #
    #         requires: ["lib/my_first_credo_check.ex"],  <-- add file here
    #         files: %{ ... },
    #         checks: [
    #           {MyFirstCredoCheck},  <-- add check here
    #         ]
    #
    #
    new_check_filename = "hello_world"
    new_check_filename = "lib/credo/#{new_check_filename}.ex"

    if File.exists?(@check_template_filename) do
      IO.puts "File exists: #{@check_template_filename}, aborted."
    else
      File.write!(new_check_filename, @default_check_template_file)
    end
    :ok
  end
end
