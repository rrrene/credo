defmodule Credo.ConfigBuilder do
  alias Credo.CLI.Filename
  alias Credo.CLI.Options
  alias Credo.ConfigFile
  alias Credo.Execution

  @pattern_split_regex ~r/,\s*/

  def parse(exec) do
    options = exec.cli_options

    case get_config_file(exec, options) do
      {:ok, config_file} ->
        exec
        |> add_config_file_to_exec(config_file)
        |> add_strict_to_exec(config_file, options)
        |> add_switches_to_exec(options.switches)
        |> run_cli_switch_plugin_param_converters()

      {:error, _} = error ->
        error
    end
  end

  defp get_config_file(exec, %Options{} = options) do
    config_name = options.switches[:config_name]
    config_filename = options.switches[:config_file]
    dir = Filename.remove_line_no_and_column(options.path)

    if is_binary(config_filename) do
      filename = Path.expand(config_filename)

      ConfigFile.read_from_file_path(exec, dir, filename, config_name)
    else
      ConfigFile.read_or_default(exec, dir, config_name)
    end
  end

  defp add_config_file_to_exec(exec, %ConfigFile{} = config_file) do
    %Execution{
      exec
      | files: config_file.files,
        color: config_file.color,
        checks: config_file.checks,
        requires: config_file.requires,
        plugins: config_file.plugins,
        parse_timeout: config_file.parse_timeout
    }
  end

  defp add_strict_to_exec(exec, %ConfigFile{} = config_file, options) do
    %Execution{
      exec
      | strict: strict_via_args_or_config_file?(options.args, config_file)
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
    |> add_switch_crash_on_error(switches)
    |> add_switch_debug(switches)
    |> add_switch_enable_disabled_checks(switches)
    |> add_switch_files_excluded(switches)
    |> add_switch_files_included(switches)
    |> add_switch_checks_without_tag(switches)
    |> add_switch_checks_with_tag(switches)
    |> add_switch_format(switches)
    |> add_switch_help(switches)
    |> add_switch_ignore(switches)
    |> add_switch_mute_exit_status(switches)
    |> add_switch_only(switches)
    |> add_switch_read_from_stdin(switches)
    |> add_switch_strict(switches)
    |> add_switch_min_priority(switches)
    |> add_switch_verbose(switches)
    |> add_switch_version(switches)
  end

  # add_switch_all

  defp add_switch_all(exec, %{all: true}) do
    %Execution{exec | all: true}
  end

  defp add_switch_all(exec, _), do: exec

  # add_switch_files_included

  defp add_switch_files_included(exec, %{files_included: [_head | _tail] = files_included}) do
    %Execution{exec | files: %{exec.files | included: files_included}}
  end

  defp add_switch_files_included(exec, _), do: exec

  # add_switch_files_excluded

  defp add_switch_files_excluded(exec, %{files_excluded: [_head | _tail] = files_excluded}) do
    %Execution{exec | files: %{exec.files | excluded: files_excluded}}
  end

  defp add_switch_files_excluded(exec, _), do: exec

  # add_switch_checks_with_tag

  defp add_switch_checks_with_tag(exec, %{
         checks_with_tag: [_head | _tail] = checks_with_tag
       }) do
    %Execution{exec | only_checks_tags: checks_with_tag}
  end

  defp add_switch_checks_with_tag(exec, _), do: exec

  # add_switch_checks_without_tag

  defp add_switch_checks_without_tag(exec, %{
         checks_without_tag: [_head | _tail] = checks_without_tag
       }) do
    %Execution{exec | ignore_checks_tags: checks_without_tag}
  end

  defp add_switch_checks_without_tag(exec, _), do: exec

  # add_switch_color

  defp add_switch_color(exec, %{color: color}) do
    %Execution{exec | color: color}
  end

  defp add_switch_color(exec, _), do: exec

  # add_switch_debug

  defp add_switch_debug(exec, %{debug: debug}) do
    %Execution{exec | debug: debug}
  end

  defp add_switch_debug(exec, _), do: exec

  # add_switch_strict

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

  # add_switch_verbose

  defp add_switch_verbose(exec, %{verbose: true}) do
    %Execution{exec | verbose: true}
  end

  defp add_switch_verbose(exec, _), do: exec

  # add_switch_crash_on_error

  defp add_switch_crash_on_error(exec, %{crash_on_error: true}) do
    %Execution{exec | crash_on_error: true}
  end

  defp add_switch_crash_on_error(exec, _), do: exec

  # add_switch_mute_exit_status

  defp add_switch_mute_exit_status(exec, %{mute_exit_status: true}) do
    %Execution{exec | mute_exit_status: true}
  end

  defp add_switch_mute_exit_status(exec, _), do: exec

  # add_switch_read_from_stdin

  defp add_switch_read_from_stdin(exec, %{read_from_stdin: true}) do
    %Execution{exec | read_from_stdin: true}
  end

  defp add_switch_read_from_stdin(exec, _), do: exec

  # add_switch_version

  defp add_switch_version(exec, %{version: true}) do
    %Execution{exec | version: true}
  end

  defp add_switch_version(exec, _), do: exec

  # add_switch_format

  defp add_switch_format(exec, %{format: format}) do
    %Execution{exec | format: format}
  end

  defp add_switch_format(exec, _), do: exec

  # add_switch_min_priority

  defp add_switch_min_priority(exec, %{min_priority: min_priority}) do
    %Execution{exec | min_priority: min_priority}
  end

  defp add_switch_min_priority(exec, _), do: exec

  # add_switch_enable_disabled_checks

  defp add_switch_enable_disabled_checks(exec, %{enable_disabled_checks: check_pattern}) do
    %Execution{exec | enable_disabled_checks: String.split(check_pattern, @pattern_split_regex)}
  end

  defp add_switch_enable_disabled_checks(exec, _), do: exec

  # add_switch_only

  # exclude/ignore certain checks
  defp add_switch_only(exec, %{only: only}) do
    add_switch_only(exec, %{checks: only})
  end

  defp add_switch_only(exec, %{checks: check_pattern}) do
    new_config = %Execution{
      exec
      | strict: true,
        only_checks: String.split(check_pattern, @pattern_split_regex)
    }

    Execution.set_strict(new_config)
  end

  defp add_switch_only(exec, _), do: exec

  # add_switch_ignore

  # exclude/ignore certain checks
  defp add_switch_ignore(exec, %{ignore: ignore}) do
    add_switch_ignore(exec, %{ignore_checks: ignore})
  end

  defp add_switch_ignore(exec, %{ignore_checks: ignore_pattern}) do
    %Execution{exec | ignore_checks: String.split(ignore_pattern, @pattern_split_regex)}
  end

  defp add_switch_ignore(exec, _), do: exec

  defp run_cli_switch_plugin_param_converters(exec) do
    Enum.reduce(
      exec.cli_switch_plugin_param_converters,
      exec,
      &reduce_converters/2
    )
  end

  defp reduce_converters({_switch_name, _plugin_mod, false}, exec) do
    exec
  end

  defp reduce_converters({switch_name, plugin_mod, true}, exec) do
    reduce_converters({switch_name, plugin_mod, switch_name}, exec)
  end

  defp reduce_converters({switch_name, plugin_mod, param_name}, exec) when is_atom(param_name) do
    converter_fun = fn switch_value -> {param_name, switch_value} end

    reduce_converters({switch_name, plugin_mod, converter_fun}, exec)
  end

  defp reduce_converters({switch_name, plugin_mod, converter_fun}, exec)
       when is_function(converter_fun) do
    case Execution.get_given_cli_switch(exec, switch_name) do
      {:ok, switch_value} ->
        validate_converter_fun_result(exec, plugin_mod, switch_name, converter_fun.(switch_value))

      _ ->
        exec
    end
  end

  defp validate_converter_fun_result(exec, plugin_mod, _switch_name, {param_name, param_value}) do
    Execution.put_plugin_param(exec, plugin_mod, param_name, param_value)
  end

  defp validate_converter_fun_result(_exec, plugin_mod, switch_name, value) do
    raise "Expected CLI switch to plugin param converter function to return a two-element tuple of {param_name, param_value}, got #{
            inspect(value)
          } (plugin: #{inspect(plugin_mod)}, switch: #{inspect(switch_name)})"
  end
end
