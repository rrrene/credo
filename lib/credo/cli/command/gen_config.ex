defmodule Credo.CLI.Command.GenConfig do
  @moduledoc false
  @shortdoc "Initialize a new .credo.exs exec file in the current directory"

  @config_filename ".credo.exs"
  @default_config_file File.read!(@config_filename)

  use Credo.CLI.Command

  alias Credo.CLI.Output.UI

  @doc false
  def call(exec, _opts) do
    create_config_file(@config_filename)

    exec
  end

  defp create_config_file(filename) do
    if File.exists?(filename) do
      UI.puts([:red, :bright, "File exists: #{filename}, aborted."])
    else
      UI.puts([:green, "* creating ", :reset, "#{filename}"])
      write_config_file(filename)
    end
  end

  defp write_config_file(filename) do
    filename
    |> Path.dirname()
    |> File.mkdir_p!()

    File.write!(filename, @default_config_file)
  end
end
