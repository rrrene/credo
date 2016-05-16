defmodule Credo.CLI.Command.ConfigInit do
  use Credo.CLI.Command

  @config_filename ".credo.exs"
  @default_config_file File.read!(@config_filename)

  def run(args, config) do
    if File.exists?(@config_filename) do
      IO.puts "File exists: #{@config_filename}, aborted."
    else
      File.write!(@config_filename, @default_config_file)
    end
    :ok
  end
end
