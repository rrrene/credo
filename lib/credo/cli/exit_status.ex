defmodule Credo.CLI.ExitStatus do
  @moduledoc false

  def generic_error, do: 128
  def config_parser_error, do: 129
  def config_loaded_but_invalid, do: 130
end
