defmodule Credo.ConfigBuilder do
  alias Credo.Execution
  alias Credo.ConfigFile
  alias Credo.CLI.Filename
  alias Credo.CLI.Options
  alias Credo.CLI.Output.UI

  def parse(%Options{} = options) do
    options.path
    |> Filename.remove_line_no_and_column
    |> ConfigFile.read_or_default(options.switches[:config_name])
    |> cast_to_exec(options)
  end

  defp cast_to_exec(%ConfigFile{} = config_file, options) do
    %Execution{
      cli_options: options,
      files: config_file.files,
      color: config_file.color,
      checks: config_file.checks,
      requires: config_file.requires,
      strict: strict_via_args_or_config_file?(options.args, config_file),
      check_for_updates: config_file.check_for_updates,
    }
    |> add_switches_to_exec(options.switches)
  end

  defp strict_via_args_or_config_file?([], config_file) do
    config_file.strict
  end
  defp strict_via_args_or_config_file?([potential_path | _], config_file) do
    user_expecting_explain_command? = Filename.contains_line_no?(potential_path)

    user_expecting_explain_command? || config_file.strict
  end

  defp add_switches_to_exec(%Execution{} = exec, switches) do
    exec
    |> set_all(switches)
    |> set_color(switches)
    |> set_strict(switches)
    |> set_crash_on_error(switches)
    |> set_mute_exit_status(switches)
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

  defp set_all(exec, %{all: true}) do
    %Execution{exec | all: true}
  end
  defp set_all(exec, _), do: exec

  defp set_color(exec, %{color: color}) do
    %Execution{exec | color: color}
  end
  defp set_color(exec, _), do: exec

  defp set_strict(exec, %{all_priorities: true}) do
    set_strict(exec, %{strict: true})
  end
  defp set_strict(exec, %{strict: true}) do
    new_config = %Execution{exec | strict: true}

    Execution.set_strict(new_config)
  end
  defp set_strict(exec, %{strict: false}) do
    new_config = %Execution{exec | strict: false}

    Execution.set_strict(new_config)
  end
  defp set_strict(exec, _), do: Execution.set_strict(exec)

  defp set_help(exec, %{help: true}) do
    %Execution{exec | help: true}
  end
  defp set_help(exec, _), do: exec

  defp set_verbose(exec, %{verbose: true}) do
    %Execution{exec | verbose: true}
  end
  defp set_verbose(exec, _), do: exec

  defp set_crash_on_error(exec, %{crash_on_error: true}) do
    %Execution{exec | crash_on_error: true}
  end
  defp set_crash_on_error(exec, _), do: exec

  defp set_mute_exit_status(exec, %{mute_exit_status: true}) do
    %Execution{exec | mute_exit_status: true}
  end
  defp set_mute_exit_status(exec, _), do: exec

  defp set_read_from_stdin(exec, %{read_from_stdin: true}) do
    %Execution{exec | read_from_stdin: true}
  end
  defp set_read_from_stdin(exec, _), do: exec

  defp set_version(exec, %{version: true}) do
    %Execution{exec | version: true}
  end
  defp set_version(exec, _), do: exec

  defp set_format(exec, %{format: format}) do
    %Execution{exec | format: format}
  end
  defp set_format(exec, _), do: exec

  defp set_min_priority(exec, %{min_priority: min_priority}) do
    %Execution{exec | min_priority: min_priority}
  end
  defp set_min_priority(exec, _), do: exec

  # exclude/ignore certain checks
  defp set_only(exec, %{only: only}) do
    set_only(exec, %{checks: only})
  end
  defp set_only(exec, %{checks: check_pattern}) do
    new_config =
      %Execution{
        exec |
        strict: true,
        only_checks: String.split(check_pattern, ",")
      }

    Execution.set_strict(new_config)
  end
  defp set_only(exec, _), do: exec

  # exclude/ignore certain checks
  defp set_ignore(exec, %{ignore: ignore}) do
    set_ignore(exec, %{ignore_checks: ignore})
  end
  defp set_ignore(exec, %{ignore_checks: ignore_pattern}) do
    %Execution{exec | ignore_checks: String.split(ignore_pattern, ",")}
  end
  defp set_ignore(exec, _), do: exec

  # DEPRECATED command line switches
  defp set_deprecated_switches(exec, %{one_line: true}) do
    UI.puts [:yellow, "[DEPRECATED] ", :faint, "--one-line is deprecated in favor of --format=oneline"]

    %Execution{exec | format: "oneline"}
  end
  defp set_deprecated_switches(exec, _), do: exec

end
