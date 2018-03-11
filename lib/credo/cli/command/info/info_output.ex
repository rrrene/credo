defmodule Credo.CLI.Command.Info.InfoOutput do
  use Credo.CLI.Output.FormatDelegator,
    default: Credo.CLI.Command.Info.Output.Default,
    json: Credo.CLI.Command.Info.Output.Json

  alias Credo.CLI.Output.UI

  def print(exec, info) do
    format_mod = format_mod(exec)

    format_mod.print(exec, info)
  end

  def print_help(exec) do
    usage = ["Usage: ", :olive, "mix credo info [options]"]

    description = """

    Shows information about Credo and its environment.
    """

    example = [
      "Example: ",
      :olive,
      :faint,
      "$ mix credo info --format=json --verbose"
    ]

    options = """

    Info options:
      -c, --checks          Only include checks that match the given strings
      -C, --config-name     Use the given config instead of "default"
      -i, --ignore-checks   Ignore checks that match the given strings
          --format          Display the list in a specific format (oneline,flycheck)
          --verbose         Display more information (e.g. checked files)

    General options:
      -v, --version         Show version
      -h, --help            Show this help
    """

    UI.puts(usage)
    UI.puts(description)
    UI.puts(example)
    UI.puts(options)

    exec
  end
end
