defmodule Credo.CLI.Options do
  defstruct command: nil,
            paths: nil,
            args: [],
            switches: nil,
            unknown_switches: [],
            unknown_args: []

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

  def parse(argv, current_dir, command_names) do
    argv
    |> OptionParser.parse(strict: @switches, aliases: @aliases)
    |> parse_result(current_dir, command_names)
  end

  defp parse_result({switches_keywords, args, unknown_switches_keywords}, current_dir, command_names) do
    {command, paths, unknown_args} = split_args(args, current_dir, command_names)

    %__MODULE__{
      command: command,
      paths: paths,
      args: unknown_args,
      switches: Enum.into(switches_keywords, %{}),
      unknown_switches: unknown_switches_keywords
    }
  end

  defp split_args([], current_dir, _) do
      {paths, unknown_args} = extract_paths([], current_dir, [], [])

      {nil, paths, unknown_args}
  end
  defp split_args([head | tail] = args, current_dir, command_names) do
    if Enum.member?(command_names, head) do
      {paths, unknown_args} = extract_paths(tail, current_dir, [], [])

      {head, paths, unknown_args}
    else
      {paths, unknown_args} = extract_paths(args, current_dir, [], [])

      {nil, paths, unknown_args}
    end
  end

  defp extract_paths([], base_dir, [], unknown_args) do
    {[base_dir], unknown_args}
  end

  defp extract_paths([], _base_dir, paths, unknown_args) do
    {paths, unknown_args}
  end
  defp extract_paths([head | tail], base_dir, paths, unknown_args) do
    path = Path.join(base_dir, head)

    if File.exists?(path) or path =~ ~r/[\?\*]/ do
      extract_paths(tail, base_dir, [path | paths], unknown_args)
    else
      extract_paths(tail, base_dir, paths, [head | unknown_args])
    end
  end
end
