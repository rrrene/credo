defmodule Credo.Execution.Task.ParseOptions do
  @moduledoc false

  use Credo.Execution.Task

  alias Credo.CLI.Options
  alias Credo.CLI.Output.UI
  alias Credo.Execution

  def call(exec, opts) do
    add_common_aliases? = opts[:parser_mode] == :preliminary
    use_strict_parser? = opts[:parser_mode] == :strict

    command_names = Execution.get_valid_command_names(exec)

    given_command_name =
      if exec.cli_options do
        exec.cli_options.command
      end

    cli_aliases =
      if add_common_aliases? do
        exec.cli_aliases ++ [h: :help, v: :version]
      else
        exec.cli_aliases
      end

    treat_unknown_args_as_files? =
      if exec.cli_options && exec.cli_options.command do
        command_name = Execution.get_command_name(exec)
        command_mod = Execution.get_command(exec, command_name)

        command_mod.treat_unknown_args_as_files?()
      else
        false
      end

    cli_options =
      Options.parse(
        use_strict_parser?,
        exec.argv,
        File.cwd!(),
        command_names,
        given_command_name,
        [UI.edge()],
        exec.cli_switches,
        cli_aliases,
        treat_unknown_args_as_files?
      )

    %Execution{exec | cli_options: cli_options}
  end
end
