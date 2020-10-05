defmodule Credo.CLI.Command.Info.InfoOutput do
  @moduledoc false

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

    options =
      """

      Info options:
        -c, --checks                  Only include checks that match the given strings
            --checks-with-tag         Only include checks that match the given tag (can be used multiple times)
            --checks-without-tag      Ignore checks that match the given tag (can be used multiple times)
            --config-file             Use the given config file
        -C, --config-name             Use the given config instead of "default"
            --enable-disabled-checks  Re-enable disabled checks that match the given strings
            --files-included          Only include these files (accepts globs, can be used multiple times)
            --files-excluded          Exclude these files (accepts globs, can be used multiple times)
            --format                  Display the list in a specific format (json,flycheck,oneline)
        -i, --ignore-checks           Ignore checks that match the given strings
            --ignore                  Alias for --ignore-checks
            --min-priority            Minimum priority to show issues (high,medium,normal,low,lower or number)
            --only                    Alias for --checks
            --verbose                 Display more information (e.g. checked files)

      General options:
        -v, --version                 Show version
        -h, --help                    Show this help

      Feedback:
        Open an issue here: https://github.com/rrrene/credo/issues
      """
      |> String.trim_trailing()

    UI.puts()
    UI.puts(usage)
    UI.puts(description)
    UI.puts(example)
    UI.puts(options)

    exec
  end
end
