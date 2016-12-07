defmodule Credo.CLI.Switches do
  @moduledoc """
  Credo.CLI.Switches is responsible for taking the options passed to the command
  line and the options set in the `.credo.exs` config file and parsing them into
  a single Credo.Config struct.
  """

  alias Credo.Config
  alias Credo.CLI.Output.UI

  def parse_to_config(config, switches) do
    config
    |> set_all(switches)
    |> set_color(switches)
    |> set_strict(switches)
    |> set_crash_on_error(switches)
    |> set_deprecated_switches(switches)
    |> set_format(switches)
    |> set_help(switches)
    |> set_ignore(switches)
    |> set_min_priority(switches)
    |> set_only(switches)
    |> set_read_from_stdin(switches)
    |> set_verbose(switches)
    |> set_version(switches)
  end

  defp set_all(config, %{all: true}) do
    %Config{config | all: true}
  end
  defp set_all(config, _), do: config

  defp set_color(config, %{color: color}) do
    %Config{config | color: color}
  end
  defp set_color(config, _), do: config

  defp set_strict(config, %{all_priorities: true}) do
    set_strict(config, %{strict: true})
  end
  defp set_strict(config, %{strict: true}) do
    new_config = %Config{config | strict: true}

    Config.set_strict(new_config)
  end
  defp set_strict(config, %{strict: false}) do
    new_config = %Config{config | strict: false}

    Config.set_strict(new_config)
  end
  defp set_strict(config, _), do: config

  defp set_help(config, %{help: true}) do
    %Config{config | help: true}
  end
  defp set_help(config, _), do: config

  defp set_verbose(config, %{verbose: true}) do
    %Config{config | verbose: true}
  end
  defp set_verbose(config, _), do: config

  defp set_crash_on_error(config, %{crash_on_error: true}) do
    %Config{config | crash_on_error: true}
  end
  defp set_crash_on_error(config, _), do: config

  defp set_read_from_stdin(config, %{read_from_stdin: true}) do
    %Config{config | read_from_stdin: true}
  end
  defp set_read_from_stdin(config, _), do: config

  defp set_version(config, %{version: true}) do
    %Config{config | version: true}
  end
  defp set_version(config, _), do: config

  defp set_format(config, %{format: format}) do
    %Config{config | format: format}
  end
  defp set_format(config, _), do: config

  defp set_min_priority(config, %{min_priority: min_priority}) do
    %Config{config | min_priority: min_priority}
  end
  defp set_min_priority(config, _), do: config

  # exclude/ignore certain checks
  defp set_only(config, %{only: only}) do
    set_only(config, %{checks: only})
  end
  defp set_only(config, %{checks: check_pattern}) do
    new_config =
      %Config{
        config |
        strict: true,
        match_checks: String.split(check_pattern, ",")
      }

    Config.set_strict(new_config)
  end
  defp set_only(config, _), do: config

  # exclude/ignore certain checks
  defp set_ignore(config, %{ignore: ignore}) do
    set_ignore(config, %{ignore_checks: ignore})
  end
  defp set_ignore(config, %{ignore_checks: ignore_pattern}) do
    %Config{config | ignore_checks: String.split(ignore_pattern, ",")}
  end
  defp set_ignore(config, _), do: config

  # DEPRECATED command line switches
  defp set_deprecated_switches(config, %{one_line: true}) do
    UI.puts [:yellow, "[DEPRECATED] ", :faint, "--one-line is deprecated in favor of --format=oneline"]

    %Config{config | format: "oneline"}
  end
  defp set_deprecated_switches(config, _), do: config
end
