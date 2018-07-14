defmodule Credo.CLI.Options do
  @moduledoc """
  The `Options` struct represents the options given on the command line.
  """

  @switches [
    all_priorities: :boolean,
    all: :boolean,
    checks: :string,
    config_name: :string,
    config_file: :string,
    color: :boolean,
    crash_on_error: :boolean,
    debug: :boolean,
    mute_exit_status: :boolean,
    format: :string,
    help: :boolean,
    ignore_checks: :string,
    ignore: :string,
    min_priority: :string,
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
    d: :debug,
    h: :help,
    i: :ignore_checks,
    v: :version
  ]

  alias Credo.Priority

  defstruct command: nil,
            path: nil,
            args: [],
            switches: nil,
            unknown_switches: [],
            unknown_args: []

  @doc """
  Returns a `Options` struct for the given parameters.

      iex> Credo.CLI.Options.parse(["alice", "--debug"], ".", ["alice", "bob", "eve"], [])
      %Credo.CLI.Options{args: [], command: "alice", path: ".", switches: %{debug: true}, unknown_args: [], unknown_switches: []}

  """
  def parse(argv, current_dir, command_names, ignored_args) do
    argv
    |> OptionParser.parse(strict: @switches, aliases: @aliases)
    |> parse_result(current_dir, command_names, ignored_args)
  end

  defp parse_result(
         {switches_keywords, args, unknown_switches_keywords},
         current_dir,
         command_names,
         ignored_args
       ) do
    args = Enum.reject(args, &Enum.member?(ignored_args, &1))
    {command, path, unknown_args} = split_args(args, current_dir, command_names)

    {switches_keywords, extra_unknown_switches} = patch_switches(switches_keywords)

    %__MODULE__{
      command: command,
      path: path,
      args: unknown_args,
      switches: Enum.into(switches_keywords, %{}),
      unknown_switches: unknown_switches_keywords ++ extra_unknown_switches
    }
  end

  defp patch_switches(switches_keywords) do
    {switches, unknowns} = Enum.map_reduce(switches_keywords, [], &patch_switch/2)
    switches = Enum.reject(switches, &(&1 == nil))
    {switches, unknowns}
  end

  defp patch_switch({:min_priority, str}, unknowns) do
    priority = priority_as_name(str) || priority_as_number(str)

    case priority do
      nil -> {nil, [{"--min-priority", str} | unknowns]}
      int -> {{:min_priority, int}, unknowns}
    end
  end

  defp patch_switch(switch, unknowns), do: {switch, unknowns}

  defp priority_as_name(str), do: Priority.to_integer(str)

  defp priority_as_number(str) do
    case Integer.parse(str) do
      {int, ""} -> int
      _ -> nil
    end
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

  defp extract_path([path | tail] = args, base_dir) do
    if File.exists?(path) or path =~ ~r/[\?\*]/ do
      {path, tail}
    else
      path_with_base = Path.join(base_dir, path)

      if File.exists?(path_with_base) do
        {path_with_base, tail}
      else
        {base_dir, args}
      end
    end
  end
end
