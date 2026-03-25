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
    |> validate_empty_ignore_checks_patterns()
    |> validate_ineffective_ignore_checks_patterns()
    |> validate_checks_scheduling_groups()
    |> remove_undefined_checks()
    |> save_validated_config()
    |> inspect_config_if_debug()
  end

  defp validate_only_checks(%Execution{config: %{only_checks: only_checks}} = exec)
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

  defp validate_empty_ignore_checks_patterns(%Execution{config: %{ignore_checks: ignore_checks}} = exec)
       when is_list(ignore_checks) do
    if Enum.any?(ignore_checks, &(&1 == "")) do
      UI.warn([
        :red,
        "** (config) Ignoring all checks, since an empty string was given as a pattern: #{inspect(ignore_checks)}"
      ])
    end

    exec
  end

  defp validate_empty_ignore_checks_patterns(exec) do
    exec
  end

  defp validate_ineffective_ignore_checks_patterns(%Execution{config: %{ignore_checks: [_ | _] = ignore_checks}} = exec) do
    case Execution.checks(exec) do
      {_, _, []} ->
        UI.warn([
          :red,
          "** (config) A pattern was given to ignore checks, but it did not match any: ",
          inspect(ignore_checks)
        ])

        exec

      _ ->
        exec
    end
  end

  defp validate_ineffective_ignore_checks_patterns(exec) do
    exec
  end

  defp validate_checks(%Execution{config: %{checks: %{enabled: enabled_checks}}} = exec) do
    Enum.each(enabled_checks, fn check_tuple ->
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
    valid_param_names = check.param_names() ++ Params.builtin_param_names()
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

  defp inspect_config_if_debug(%Execution{config: %{debug: true}} = exec) do
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

  defp remove_undefined_checks(
         %Execution{config: %{checks: %{enabled: enabled_checks, disabled: disabled_checks}}} = exec
       ) do
    enabled_checks = Enum.filter(enabled_checks, &Check.defined?/1)
    disabled_checks = Enum.filter(disabled_checks, &Check.defined?/1)

    Execution.put_config(exec, :checks, %{enabled: enabled_checks, disabled: disabled_checks})
  end

  defp validate_checks_scheduling_groups(exec) do
    {checks, _only_matching, _ignore_matching} = Execution.checks(exec)
    default_group_number = Credo.Check.default_scheduled_in_group()

    if checks != [] && Enum.all?(checks, fn {check, _} -> check.scheduled_in_group() > default_group_number end) do
      UI.warn([
        :red,
        "** (config) All checks scheduled to run seem to be depending on the results of earlier checks, but there are none."
      ])
    end

    exec
  end

  defp save_validated_config(exec) do
    Execution.put_assign(exec, "credo.validated_config", exec.config)
  end
end
