defmodule Credo.CLI.SwitchesParser do
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

  def parse(argv) do
    argv
    |> OptionParser.parse(strict: @switches, aliases: @aliases)
    |> parse_result()
  end

  defp parse_result({switches_keywords, args, unknown_switches_keywords}) do
    base_switches = %{args: args, unknown_switches: unknown_switches_keywords}
    Enum.into(switches_keywords, base_switches)
  end
end
