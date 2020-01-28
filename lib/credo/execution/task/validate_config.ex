defmodule Credo.Execution.Task.ValidateConfig do
  @moduledoc false

  use Credo.Execution.Task

  alias Credo.CLI.Output.UI

  def call(exec, _opts) do
    exec
    |> validate_checks()
    |> remove_missing_checks()
    |> inspect_config_if_debug()
  end

  defp validate_checks(%Execution{checks: checks} = exec) do
    Enum.each(checks, &warn_if_check_missing/1)

    exec
  end

  defp inspect_config_if_debug(%Execution{debug: true} = exec) do
    require Logger

    Logger.debug(fn ->
      """
      Execution struct after #{__MODULE__}:

      #{inspect(exec, pretty: true)}
      """
    end)

    exec
  end

  defp inspect_config_if_debug(exec), do: exec

  defp remove_missing_checks(%Execution{checks: checks} = exec) do
    checks = Enum.filter(checks, &check_defined?/1)

    %Execution{exec | checks: checks}
  end

  defp check_defined?({atom, _}), do: check_defined?({atom})

  defp check_defined?({atom}) do
    Credo.Backports.Code.ensure_compiled?(atom)
  end

  defp warn_if_check_missing({atom, _}), do: warn_if_check_missing({atom})

  defp warn_if_check_missing({atom}) do
    unless check_defined?({atom}) do
      check_name =
        atom
        |> to_string()
        |> String.replace(~r/^Elixir\./, "")

      UI.warn("Ignoring an undefined check: #{check_name}")
    end
  end
end
