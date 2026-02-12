defmodule Credo.ConfigBuilder do
  alias Credo.CLI.Filename
  alias Credo.CLI.Options
  alias Credo.ConfigFile
  alias Credo.Execution

  import Credo.Execution, only: [put_config: 3]

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
    config = %{
      exec.config
      | requires: config_file.requires,
        plugins: config_file.plugins,
        checks: config_file.checks,
        color: config_file.color,
        files: config_file.files,
        parse_timeout: config_file.parse_timeout
    }

    %{
      exec
      | config: config
    }
  end

  defp add_strict_to_exec(exec, %ConfigFile{} = config_file, options) do
    put_config(exec, :strict, strict_via_args_or_config_file?(options.args, config_file))
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

  # add_switch_files_included

  defp add_switch_files_included(exec, %{files_included: [_head | _tail] = files_included}) do
    files = %{exec.config.files | included: files_included}

    put_config(exec, :files, files)
  end

  defp add_switch_files_included(exec, _), do: exec

  # add_switch_files_excluded

  defp add_switch_files_excluded(exec, %{files_excluded: [_head | _tail] = files_excluded}) do
    files = %{exec.config.files | excluded: files_excluded}

    put_config(exec, :files, files)
  end

  defp add_switch_files_excluded(exec, _), do: exec

  # add_switch_checks_with_tag

  defp add_switch_checks_with_tag(exec, %{
         checks_with_tag: [_head | _tail] = checks_with_tag
       }) do
    put_config(exec, :only_checks_tags, checks_with_tag)
  end

  defp add_switch_checks_with_tag(exec, _), do: exec

  # add_switch_checks_without_tag

  defp add_switch_checks_without_tag(exec, %{checks_without_tag: [_head | _tail] = checks_without_tag}) do
    put_config(exec, :checks_without_tag, checks_without_tag)
  end

  defp add_switch_checks_without_tag(exec, _), do: exec

  # add_switch_color

  defp add_switch_color(exec, %{color: color}) do
    put_config(exec, :color, color)
  end

  defp add_switch_color(exec, _), do: exec

  # add_switch_debug

  defp add_switch_debug(exec, %{debug: debug}) when is_boolean(debug) do
    put_config(exec, :debug, debug)
  end

  defp add_switch_debug(exec, _), do: exec

  # add_switch_strict

  defp add_switch_strict(exec, %{all_priorities: true}) do
    add_switch_strict(exec, %{strict: true})
  end

  defp add_switch_strict(exec, %{strict: value}) when is_boolean(value) do
    exec
    |> put_config(:strict, value)
    |> Execution.set_strict()
  end

  defp add_switch_strict(exec, _), do: Execution.set_strict(exec)

  defp add_switch_help(exec, %{help: true}) do
    put_config(exec, :help, true)
  end

  defp add_switch_help(exec, _), do: exec

  # add_switch_verbose

  defp add_switch_verbose(exec, %{verbose: true}) do
    put_config(exec, :verbose, true)
  end

  defp add_switch_verbose(exec, _), do: exec

  # add_switch_crash_on_error

  defp add_switch_crash_on_error(exec, %{crash_on_error: true}) do
    put_config(exec, :crash_on_error, true)
  end

  defp add_switch_crash_on_error(exec, _), do: exec

  # add_switch_mute_exit_status

  defp add_switch_mute_exit_status(exec, %{mute_exit_status: true}) do
    put_config(exec, :mute_exit_status, true)
  end

  defp add_switch_mute_exit_status(exec, _), do: exec

  # add_switch_read_from_stdin

  defp add_switch_read_from_stdin(exec, %{read_from_stdin: true}) do
    put_config(exec, :read_from_stdin, true)
  end

  defp add_switch_read_from_stdin(exec, _), do: exec

  # add_switch_version

  defp add_switch_version(exec, %{version: true}) do
    put_config(exec, :version, true)
  end

  defp add_switch_version(exec, _), do: exec

  # add_switch_format

  defp add_switch_format(exec, %{format: format}) do
    put_config(exec, :format, format)
  end

  defp add_switch_format(exec, _), do: exec

  # add_switch_min_priority

  defp add_switch_min_priority(exec, %{min_priority: min_priority}) do
    put_config(exec, :min_priority, min_priority)
  end

  defp add_switch_min_priority(exec, _), do: exec

  # add_switch_enable_disabled_checks

  defp add_switch_enable_disabled_checks(exec, %{enable_disabled_checks: check_pattern}) do
    put_config(exec, :enable_disabled_checks, String.split(check_pattern, pattern_split_regex()))
  end

  defp add_switch_enable_disabled_checks(exec, _), do: exec

  # add_switch_only

  # exclude/ignore certain checks
  defp add_switch_only(exec, %{only: only}) do
    add_switch_only(exec, %{checks: only})
  end

  # this catches a `--checks/only` without an argument after it
  defp add_switch_only(exec, %{checks: true}) do
    exec
  end

  defp add_switch_only(exec, %{checks: check_pattern}) do
    exec
    |> put_config(:only_checks, String.split(check_pattern, pattern_split_regex()))
    |> put_config(:strict, true)
    |> Execution.set_strict()
  end

  defp add_switch_only(exec, _), do: exec

  # add_switch_ignore

  # exclude/ignore certain checks
  defp add_switch_ignore(exec, %{ignore: ignore}) do
    put_config(exec, :ignore_checks, ignore)
  end

  # this catches a `--ignore-checks/ignore` without an argument after it
  defp add_switch_ignore(exec, %{ignore_checks: true}) do
    exec
  end

  defp add_switch_ignore(exec, %{ignore_checks: ignore_pattern}) do
    put_config(exec, :ignore_checks, String.split(ignore_pattern, pattern_split_regex()))
  end

  defp add_switch_ignore(exec, _), do: exec

  defp run_cli_switch_plugin_param_converters(exec) do
    exec
    |> Execution.get_private(:cli_switch_plugin_param_converters)
    |> Enum.reduce(exec, &reduce_converters/2)
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
    raise "Expected CLI switch to plugin param converter function to return a two-element tuple of {param_name, param_value}, got #{inspect(value)} (plugin: #{inspect(plugin_mod)}, switch: #{inspect(switch_name)})"
  end

  # moved to private function due to deprecation of regexes
  # in module attributes in Elixir 1.19
  defp pattern_split_regex, do: ~r/,\s*/
end
