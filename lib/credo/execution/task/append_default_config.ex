defmodule Credo.Execution.Task.AppendDefaultConfig do
  @moduledoc false

  use Credo.Execution.Task

  alias Credo.Execution

  @default_config_filename ".credo.exs"
  @default_config_file_content File.read!(@default_config_filename)
  @origin_credo :credo

  def call(exec, _opts) do
    Execution.append_config_file(exec, {@origin_credo, nil, @default_config_file_content})
  end
end
