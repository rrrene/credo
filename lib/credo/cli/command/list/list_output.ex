defmodule Credo.CLI.Command.List.ListOutput do
  use Credo.CLI.Output.FormatDelegator,
    default: Credo.CLI.Command.List.Output.Default,
    flycheck: Credo.CLI.Command.List.Output.FlyCheck,
    oneline: Credo.CLI.Command.List.Output.Oneline,
    json: Credo.CLI.Command.List.Output.Json

  alias Credo.CLI.Output.UI

  def print_help(exec) do
    usage = ["Usage: ", :olive, "mix credo list [paths] [options]"]

    description = """

    Lists objects that Credo thinks can be improved ordered by their priority.
    """

    example = [
      "Example: ",
      :olive,
      :faint,
      "$ mix credo list lib/**/*.ex --format=oneline"
    ]

    options = """

    Arrows (↑ ↗ → ↘ ↓) hint at the importance of an issue.

    List options:
      -a, --all             Show all issues
      -A, --all-priorities  Show all issues including low priority ones
          --min-priority    Minimum priority to show issues (high,medium,normal,low,lower or number)
      -c, --checks          Only include checks that match the given strings
      -C, --config-name     Use the given config instead of "default"
      -i, --ignore-checks   Ignore checks that match the given strings
          --format          Display the list in a specific format (oneline,flycheck)

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
