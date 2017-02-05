defmodule Credo.CLI.Options do
  defstruct command: nil,
            path: nil,
            switches: nil,
            unknown_switches: nil,
            unknown_args: nil

  # %Credo.CLI.Options{
  #   command: "suggest", # based on collection of commands
  #   given_directory: "",
  #   given_switches: %{
  #     based_on: :@switches,
  #   },
  #   unknown_switches: [],
  #   unknown_args: []
  # }

  @switches [
    all: :boolean,
    all_priorities: :boolean,
    checks: :string,
    color: :boolean,
    crash_on_error: :boolean,
    format: :string,
    help: :boolean,
    ignore_checks: :string,
    min_priority: :integer,
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
    |> parse_result(dir)
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

  defp split_args(tail, dir, command_names) when command in command_names do
    command = "TODO"
    {path, unknown_args} = extract_path(tail, dir)

    {command, path, unknown_args}
  end

  def extract_path([], base_dir) do
    {base_dir, []}
  end
  def extract_path([head | tail], base_dir) do
    path = Path.join(base_dir, head)

    {path, tail}
  end
end
