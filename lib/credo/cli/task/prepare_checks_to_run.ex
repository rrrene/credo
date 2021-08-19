defmodule Credo.CLI.Task.PrepareChecksToRun do
  @moduledoc false

  use Credo.Execution.Task

  def call(exec, _opts \\ []) do
    source_files = Execution.get_source_files(exec)

    exec
    |> set_config_comments(source_files)
    |> enable_disabled_checks_if_applicable()
    |> exclude_low_priority_checks(exec.min_priority - 9)
    |> exclude_checks_based_on_elixir_version
  end

  defp set_config_comments(exec, source_files) do
    config_comment_map =
      source_files
      |> Credo.Check.ConfigCommentFinder.run()
      |> Enum.into(%{})

    %Execution{exec | config_comment_map: config_comment_map}
  end

  defp enable_disabled_checks_if_applicable(%Execution{enable_disabled_checks: nil} = exec) do
    exec
  end

  defp enable_disabled_checks_if_applicable(exec) do
    enable_disabled_checks_regexes = to_match_regexes(exec.enable_disabled_checks)

    enable_disabled_checks =
      Enum.map(exec.checks.disabled, fn
        {check, params} ->
          if matches?(to_string(check), enable_disabled_checks_regexes) do
            {check, params}
          else
            {check, false}
          end
      end)

    checks = Keyword.merge(exec.checks.enabled, enable_disabled_checks)

    %Execution{exec | checks: %{enabled: checks, disabled: exec.checks.disabled}}
  end

  defp exclude_low_priority_checks(exec, below_priority) do
    checks =
      Enum.reject(exec.checks.enabled, fn
        # deprecated
        {check} ->
          Credo.Priority.to_integer(check.base_priority) < below_priority

        {_check, false} ->
          true

        {check, params} ->
          priority =
            params
            |> Credo.Check.Params.priority(check)
            |> Credo.Priority.to_integer()

          priority < below_priority
      end)

    %Execution{exec | checks: %{enabled: checks, disabled: exec.checks.disabled}}
  end

  defp exclude_checks_based_on_elixir_version(exec) do
    elixir_version = System.version()
    skipped_checks = Enum.reject(exec.checks.enabled, &matches_requirement?(&1, elixir_version))
    checks = Enum.filter(exec.checks.enabled, &matches_requirement?(&1, elixir_version))

    %Execution{
      exec
      | checks: %{enabled: checks, disabled: exec.checks.disabled},
        skipped_checks: skipped_checks
    }
  end

  defp matches_requirement?({check, _}, elixir_version) do
    matches_requirement?({check}, elixir_version)
  end

  defp matches_requirement?({check}, elixir_version) do
    Version.match?(elixir_version, check.elixir_version)
  end

  defp to_match_regexes(nil), do: []

  defp to_match_regexes(list) do
    Enum.map(list, fn match_check ->
      {:ok, match_pattern} = Regex.compile(match_check, "i")
      match_pattern
    end)
  end

  defp matches?(_string, nil), do: false
  defp matches?(string, list) when is_list(list), do: Enum.any?(list, &matches?(string, &1))
  defp matches?(string, %Regex{} = regex), do: Regex.match?(regex, string)
  defp matches?(string, pattern) when is_binary(pattern), do: String.contains?(string, pattern)
end
