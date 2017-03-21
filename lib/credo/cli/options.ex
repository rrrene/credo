defmodule Credo.CLI.Options do
  defstruct command: nil,
            path: nil,
            args: [],
            switches: nil,
            unknown_switches: [],
            unknown_args: []

  @switches [
    all_priorities: :boolean,
    all: :boolean,
    checks: :string,
    config_name: :string,
    color: :boolean,
    crash_on_error: :boolean,
    format: :string,
    help: :boolean,
    ignore_checks: :string,
    ignore: :string,
    min_priority: :integer,
    only: :string,
    read_from_stdin: :boolean,
    strict: :boolean,
    verbose: :boolean,
    version: :boolean
  ]
  @aliases [
    a: :all,
    A: :all_priorities,
    c: :checks,
    C: :config_name,
    h: :help,
    i: :ignore_checks,
    v: :version
  ]

  def parse(argv, current_dir, command_names) do
    argv
    |> OptionParser.parse(strict: @switches, aliases: @aliases)
    |> parse_result(current_dir, command_names)
  end

  defp parse_result({switches_keywords, args, unknown_switches_keywords}, current_dir, command_names) do
    {command, path, unknown_args} = split_args(args, current_dir, command_names)

    %__MODULE__{
      command: command,
      path: path,
      args: unknown_args,
      switches: Enum.into(switches_keywords, %{}),
      unknown_switches: unknown_switches_keywords
    }
  end

  defp split_args([], current_dir, _) do
      {path, unknown_args} = extract_path([], current_dir)

      {nil, path, unknown_args}
  end
  defp split_args([head | tail] = args, current_dir, command_names) do
    if Enum.member?(command_names, head) do
      {path, unknown_args} = extract_path(tail, current_dir)

      {head, path, unknown_args}
    else
      {path, unknown_args} = extract_path(args, current_dir)

      {nil, path, unknown_args}
    end
  end

  defp extract_path([], base_dir) do
    {base_dir, []}
  end
  defp extract_path([head | tail] = args, base_dir) do
    path = Path.join(base_dir, head)

    if File.exists?(path) or path =~ ~r/[\?\*]/ do
      {path, tail}
    else
      {base_dir, args}
    end
  end
end
