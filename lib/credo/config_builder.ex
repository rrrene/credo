defmodule Credo.ConfigBuilder do
  alias Credo.Execution
  alias Credo.ConfigFile
  alias Credo.CLI.Filename
  alias Credo.CLI.Output.UI

  def parse(exec) do
    options = exec.cli_options
    config_name = options.switches[:config_name]
    config_file =
      options.path
      |> Filename.remove_line_no_and_column
      |> ConfigFile.read_or_default(config_name)

    exec
    |> add_config_file_to_exec(config_file)
    |> add_strict_to_exec(config_file, options)
    |> add_switches_to_exec(options.switches)
  end

  defp add_config_file_to_exec(exec, %ConfigFile{} = config_file) do
    %Execution{
      exec |
      files: config_file.files,
      color: config_file.color,
      checks: config_file.checks,
      requires: config_file.requires,
      check_for_updates: config_file.check_for_updates,
    }
  end

  defp add_strict_to_exec(exec, %ConfigFile{} = config_file, options) do
    %Execution{
      exec |
      strict: strict_via_args_or_config_file?(options.args, config_file),
    }
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
    |> add_switch_all(switches)
    |> add_switch_color(switches)
    |> add_switch_strict(switches)
    |> add_switch_crash_on_error(switches)
    |> add_switch_mute_exit_status(switches)
    |> add_switch_deprecated_switches(switches)
    |> add_switch_format(switches)
    |> add_switch_help(switches)
    |> add_switch_ignore(switches)
    |> add_switch_min_priority(switches)
    |> add_switch_only(switches)
    |> add_switch_read_from_stdin(switches)
    |> add_switch_verbose(switches)
    |> add_switch_version(switches)
  end

  defp add_switch_all(exec, %{all: true}) do
    %Execution{exec | all: true}
  end
  defp add_switch_all(exec, _), do: exec

  defp add_switch_color(exec, %{color: color}) do
    %Execution{exec | color: color}
  end
  defp add_switch_color(exec, _), do: exec

  defp add_switch_strict(exec, %{all_priorities: true}) do
    add_switch_strict(exec, %{strict: true})
  end
  defp add_switch_strict(exec, %{strict: true}) do
    new_config = %Execution{exec | strict: true}

    Execution.set_strict(new_config)
  end
  defp add_switch_strict(exec, %{strict: false}) do
    new_config = %Execution{exec | strict: false}

    Execution.set_strict(new_config)
  end
  defp add_switch_strict(exec, _), do: Execution.set_strict(exec)

  defp add_switch_help(exec, %{help: true}) do
    %Execution{exec | help: true}
  end
  defp add_switch_help(exec, _), do: exec

  defp add_switch_verbose(exec, %{verbose: true}) do
    %Execution{exec | verbose: true}
  end
  defp add_switch_verbose(exec, _), do: exec

  defp add_switch_crash_on_error(exec, %{crash_on_error: true}) do
    %Execution{exec | crash_on_error: true}
  end
  defp add_switch_crash_on_error(exec, _), do: exec

  defp add_switch_mute_exit_status(exec, %{mute_exit_status: true}) do
    %Execution{exec | mute_exit_status: true}
  end
  defp add_switch_mute_exit_status(exec, _), do: exec

  defp add_switch_read_from_stdin(exec, %{read_from_stdin: true}) do
    %Execution{exec | read_from_stdin: true}
  end
  defp add_switch_read_from_stdin(exec, _), do: exec

  defp add_switch_version(exec, %{version: true}) do
    %Execution{exec | version: true}
  end
  defp add_switch_version(exec, _), do: exec

  defp add_switch_format(exec, %{format: format}) do
    %Execution{exec | format: format}
  end
  defp add_switch_format(exec, _), do: exec

  defp add_switch_min_priority(exec, %{min_priority: min_priority}) do
    %Execution{exec | min_priority: min_priority}
  end
  defp add_switch_min_priority(exec, _), do: exec

  # exclude/ignore certain checks
  defp add_switch_only(exec, %{only: only}) do
    add_switch_only(exec, %{checks: only})
  end
  defp add_switch_only(exec, %{checks: check_pattern}) do
    new_config =
      %Execution{
        exec |
        strict: true,
        only_checks: String.split(check_pattern, ",")
      }

    Execution.set_strict(new_config)
  end
  defp add_switch_only(exec, _), do: exec

  # exclude/ignore certain checks
  defp add_switch_ignore(exec, %{ignore: ignore}) do
    add_switch_ignore(exec, %{ignore_checks: ignore})
  end
  defp add_switch_ignore(exec, %{ignore_checks: ignore_pattern}) do
    %Execution{exec | ignore_checks: String.split(ignore_pattern, ",")}
  end
  defp add_switch_ignore(exec, _), do: exec

  # DEPRECATED command line switches
  defp add_switch_deprecated_switches(exec, %{one_line: true}) do
    UI.puts [:yellow, "[DEPRECATED] ", :faint, "--one-line is deprecated in favor of --format=oneline"]

    %Execution{exec | format: "oneline"}
  end
  defp add_switch_deprecated_switches(exec, _), do: exec

end
