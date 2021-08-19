defmodule Credo.Execution.Task.ValidateConfig do
  @moduledoc false

  use Credo.Execution.Task

  alias Credo.Check
  alias Credo.Check.Params
  alias Credo.CLI.Output.UI

  def call(exec, _opts) do
    exec
    |> validate_checks()
    |> validate_only_checks()
    |> validate_ignore_checks()
    |> remove_missing_checks()
    |> inspect_config_if_debug()
  end

  defp validate_only_checks(%Execution{only_checks: only_checks} = exec)
       when is_list(only_checks) do
    if Enum.any?(only_checks, &(&1 == "")) do
      UI.warn([
        :red,
        "** (config) Including all checks, since an empty string was given as a pattern: #{inspect(only_checks)}"
      ])
    end

    exec
  end

  defp validate_only_checks(exec) do
    exec
  end

  defp validate_ignore_checks(%Execution{ignore_checks: ignore_checks} = exec)
       when is_list(ignore_checks) do
    if Enum.any?(ignore_checks, &(&1 == "")) do
      UI.warn([
        :red,
        "** (config) Ignoring all checks, since an empty string was given as a pattern: #{inspect(ignore_checks)}"
      ])
    end

    exec
  end

  defp validate_ignore_checks(exec) do
    exec
  end

  defp validate_checks(%Execution{checks: %{enabled: checks}} = exec) do
    Enum.each(checks, fn check_tuple ->
      warn_if_check_missing(check_tuple)
      warn_if_check_params_invalid(check_tuple)
    end)

    exec
  end

  defp warn_if_check_params_invalid({_check, false}), do: nil
  defp warn_if_check_params_invalid({_check, []}), do: nil

  defp warn_if_check_params_invalid({check, params}) do
    if Check.defined?(check) do
      do_warn_if_check_params_invalid({check, params})
    end
  end

  defp do_warn_if_check_params_invalid({check, params}) do
    valid_param_names = check.param_names ++ Params.builtin_param_names()
    check = check |> to_string |> String.to_existing_atom()

    Enum.each(params, fn {param_name, _param_value} ->
      unless Enum.member?(valid_param_names, param_name) do
        candidate = find_best_match(valid_param_names, param_name)
        warning = warning_message_for(check, param_name, candidate)

        UI.warn([:red, warning])
      end
    end)
  end

  defp warning_message_for(check, param_name, candidate) do
    if candidate do
      "** (config) #{check_name(check)}: unknown param `#{param_name}`. Did you mean `#{candidate}`?"
    else
      "** (config) #{check_name(check)}: unknown param `#{param_name}`."
    end
  end

  defp find_best_match(candidates, given, threshold \\ 0.8) do
    given_string = to_string(given)

    {jaro_distance, candidate} =
      candidates
      |> Enum.map(fn candidate_name ->
        distance = String.jaro_distance(given_string, to_string(candidate_name))
        {distance, candidate_name}
      end)
      |> Enum.sort()
      |> List.last()

    if jaro_distance > threshold do
      candidate
    end
  end

  defp warn_if_check_missing({check, _params}) do
    unless Check.defined?(check) do
      UI.warn([:red, "** (config) Ignoring an undefined check: #{check_name(check)}"])
    end
  end

  defp check_name(atom) do
    atom
    |> to_string()
    |> String.replace(~r/^Elixir\./, "")
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

  defp remove_missing_checks(
         %Execution{checks: %{enabled: enabled_checks, disabled: disabled_checks}} = exec
       ) do
    enabled_checks = Enum.filter(enabled_checks, &Check.defined?/1)
    disabled_checks = Enum.filter(disabled_checks, &Check.defined?/1)

    %Execution{exec | checks: %{enabled: enabled_checks, disabled: disabled_checks}}
  end
end
