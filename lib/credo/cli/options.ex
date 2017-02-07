defmodule Credo.CLI.Options do
  defstruct command: nil,
            path: nil,
            switches: nil,
            unknown_switches: nil,
            unknown_args: nil

  @switches [
    all_priorities: :boolean,
    all: :boolean,
    checks: :string,
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

  def parse(argv, dir, command_names) do
    argv
    |> OptionParser.parse(strict: @switches, aliases: @aliases)
    |> parse_result(dir, command_names)
  end

  defp parse_result({switches_keywords, args, unknown_switches_keywords}, dir, command_names) do
    {command, path, unknown_args} = split_args(args, dir, command_names)

    %__MODULE__{
      command: command,
      path: path,
      switches: Enum.into(switches_keywords, %{}),
      unknown_args: unknown_args,
      unknown_switches: unknown_switches_keywords
    }
  end

  defp split_args([], dir, _) do
      {path, unknown_args} = extract_path([], dir)

      {nil, path, unknown_args}
  end
  defp split_args([head | tail] = args, dir, command_names) do
    if Enum.member?(command_names, head) do
      {path, unknown_args} = extract_path(tail, dir)

      {head, path, unknown_args}
    else
      {path, unknown_args} = extract_path(args, dir)

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
