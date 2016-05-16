defmodule Credo.CLI.Command.CheckNew do
  use Credo.CLI.Command

  @check_template_filename ".template.check.ex"
  @default_check_template_file File.read!(@check_template_filename)

  def run(args, config) do
    # TODO: print warning for missing filename
    # TODO: get filename from args
    # TODO: print info how to add it to .credo.exs
    new_check_filename = "hello_world"
    new_check_filename = "lib/credo/#{}.ex"

    if File.exists?(@check_template_filename) do
      IO.puts "File exists: #{@check_template_filename}, aborted."
    else
      File.write!(new_check_filename, @default_check_template_file)
    end
    :ok
  end
end
