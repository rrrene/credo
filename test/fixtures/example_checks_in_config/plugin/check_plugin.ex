defmodule ExampleCheckPlugin do
  @config_file File.read!(Path.join(__DIR__, ".credo.exs"))

  import Credo.Plugin

  def init(exec) do
    register_default_config(exec, @config_file)
  end
end
