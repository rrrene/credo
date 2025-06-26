defmodule Credo.CLI.Command.Suggest.SuggestOutput do
  @moduledoc false

  use Credo.CLI.Output.FormatDelegator,
    default: Credo.CLI.Command.Suggest.Output.Default,
    flycheck: Credo.CLI.Command.Suggest.Output.FlyCheck,
    oneline: Credo.CLI.Command.Suggest.Output.Oneline,
    json: Credo.CLI.Command.Suggest.Output.Json,
    sarif: Credo.CLI.Command.Suggest.Output.Sarif

  alias Credo.CLI.Output.UI

  def print_help(exec) do
    usage = ["Usage: ", :olive, "mix credo suggest [options]"]

    description = """

    Suggests objects from every category that Credo thinks can be improved.
    """

    example = [
      "Examples:\n",
      :olive,
      "  $ mix credo suggest --format json\n",
      "  $ mix credo suggest \"lib/**/*.ex\" --only consistency --all\n",
      "  $ mix credo suggest --checks-without-tag formatter --checks-without-tag controversial"
    ]

    options =
      """

      Arrows (↑ ↗ → ↘ ↓) hint at the importance of an issue.

      Suggest options:
        -a, --all                     Show all issues
        -A, --all-priorities          Show all issues including low priority ones
        -c, --checks                  Only include checks that match the given strings
            --checks-with-tag         Only include checks that match the given tag (can be used multiple times)
            --checks-without-tag      Ignore checks that match the given tag (can be used multiple times)
            --config-file             Use the given config file
        -C, --config-name             Use the given config instead of "default"
            --enable-disabled-checks  Re-enable disabled checks that match the given strings
            --files-included          Only include these files (accepts globs, can be used multiple times)
            --files-excluded          Exclude these files (accepts globs, can be used multiple times)
            --format                  Display the list in a specific format (json,flycheck,sarif,oneline)
        -i, --ignore-checks           Ignore checks that match the given strings
            --ignore                  Alias for --ignore-checks
            --min-priority            Minimum priority to show issues (higher,high,normal,low,ignore or number)
            --mute-exit-status        Exit with status zero even if there are issues
            --only                    Alias for --checks
            --strict                  Alias for --all-priorities

      General options:
            --[no-]color              Toggle colored output
        -v, --version                 Show version
        -h, --help                    Show this help

      Find advanced usage instructions and more examples here:
        https://hexdocs.pm/credo/suggest_command.html

      Give feedback and open an issue here:
        https://github.com/rrrene/credo/issues
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
