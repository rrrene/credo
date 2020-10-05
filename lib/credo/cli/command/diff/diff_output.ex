defmodule Credo.CLI.Command.Diff.DiffOutput do
  @moduledoc false

  use Credo.CLI.Output.FormatDelegator,
    default: Credo.CLI.Command.Diff.Output.Default,
    flycheck: Credo.CLI.Command.Diff.Output.FlyCheck,
    oneline: Credo.CLI.Command.Diff.Output.Oneline,
    json: Credo.CLI.Command.Diff.Output.Json

  alias Credo.CLI.Output.UI

  def print_help(exec) do
    usage = ["Usage: ", :olive, "mix credo diff [paths] [options]"]

    description = """

    Diffs objects against a point in Git's history.
    """

    example = [
      "Examples:\n",
      :olive,
      "  $ mix credo diff lib/**/*.ex HEAD\n",
      "  $ mix credo diff v1.4.0\n",
      "  $ mix credo diff main"
    ]

    options =
      """

      Arrows (↑ ↗ → ↘ ↓) hint at the importance of an issue.

      Diff options:
        -a, --all                     Show all new issues
        -A, --all-priorities          Show all new issues including low priority ones
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
            --mute-exit-status        Exit with status zero even if there are issues
            --only                    Alias for --checks
            --strict                  Alias for --all-priorities

      General options:
            --[no-]color              Toggle colored output
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
