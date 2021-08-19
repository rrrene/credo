defmodule Credo.Execution.Task.AppendExtraConfig do
  @moduledoc false

  use Credo.Execution.Task

  alias Credo.Execution

  @extra_config_env_name "CREDO_EXTRA_CONFIG"
  @origin_extra_config :env

  def call(exec, _opts) do
    case System.get_env(@extra_config_env_name) do
      nil -> exec
      "" -> exec
      value -> Execution.append_config_file(exec, {@origin_extra_config, nil, value})
    end
  end
end
