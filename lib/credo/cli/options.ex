defmodule Credo.CLI.Options do
  @moduledoc """
  The `Options` struct represents the options given on the command line.

  The `Options` struct is stored as part of the `Execution` struct.
  """

  alias Credo.Priority

  defstruct command: nil,
            path: nil,
            args: [],
            switches: nil,
            unknown_switches: [],
            unknown_args: []

  @deprecated "Options.parse/7 is deprecated, use Options.parse/8 instead"
  def parse(
        argv,
        current_dir,
        command_names,
        given_command_name,
        ignored_args,
        switches_definition,
        aliases
      ) do
    parse(
      true,
      argv,
      current_dir,
      command_names,
      given_command_name,
      ignored_args,
      switches_definition,
      aliases
    )
  end

  @doc """
  Returns a `Options` struct for the given parameters.
  """
  def parse(
        true = _use_strict_parser?,
        argv,
        current_dir,
        command_names,
        given_command_name,
        ignored_args,
        switches_definition,
        aliases
      ) do
    argv
    |> OptionParser.parse(strict: switches_definition, aliases: aliases)
    |> parse_result(
      current_dir,
      command_names,
      given_command_name,
      ignored_args,
      switches_definition
    )
  end

  def parse(
        false = _use_strict_parser?,
        argv,
        current_dir,
        command_names,
        given_command_name,
        ignored_args,
        switches_definition,
        aliases
      ) do
    argv
    |> OptionParser.parse(switches: switches_definition, aliases: aliases)
    |> parse_result(
      current_dir,
      command_names,
      given_command_name,
      ignored_args,
      []
    )
  end

  defp parse_result(
         {switches_keywords, args, unknown_switches_keywords},
         current_dir,
         command_names,
         given_command_name,
         ignored_args,
         switches_definition
       ) do
    args = Enum.reject(args, &Enum.member?(ignored_args, &1))

    {command, path, unknown_args} =
      split_args(args, current_dir, command_names, switches_keywords[:working_dir])

    {switches_keywords, extra_unknown_switches} = patch_switches(switches_keywords)

    switch_definitions_for_lists =
      Enum.filter(switches_definition, fn
        {_name, :keep} -> true
        {_name, [_, :keep]} -> true
        {_name, _value} -> false
      end)

    switches_with_lists_as_map =
      switch_definitions_for_lists
      |> Enum.map(fn {name, _value} ->
        {name, Keyword.get_values(switches_keywords, name)}
      end)
      |> Enum.into(%{})

    switches =
      switches_keywords
      |> Enum.into(%{})
      |> Map.merge(switches_with_lists_as_map)

    {path, switches} =
      if File.dir?(path) do
        {path, switches}
      else
        {current_dir, Map.put(switches, :files_included, [path])}
      end

    %__MODULE__{
      command: command || given_command_name,
      path: path,
      args: unknown_args,
      switches: switches,
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

  defp split_args([], current_dir, _, nil) do
    {path, unknown_args} = extract_path([], current_dir)

    {nil, path, unknown_args}
  end

  defp split_args([], _current_dir, _, given_working_dir) do
    {nil, given_working_dir, []}
  end

  defp split_args([head | tail] = args, current_dir, command_names, nil) do
    if Enum.member?(command_names, head) do
      {path, unknown_args} = extract_path(tail, current_dir)

      {head, path, unknown_args}
    else
      {path, unknown_args} = extract_path(args, current_dir)

      {nil, path, unknown_args}
    end
  end

  defp split_args([head | tail] = args, _current_dir, command_names, given_working_dir) do
    if Enum.member?(command_names, head) do
      {head, given_working_dir, tail}
    else
      {nil, given_working_dir, args}
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
