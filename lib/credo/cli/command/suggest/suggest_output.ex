defmodule Credo.CLI.Command.Suggest.SuggestOutput do
  use Credo.CLI.Output.FormatDelegator,
    default: Credo.CLI.Command.Suggest.Output.Default,
    flycheck: Credo.CLI.Command.Suggest.Output.FlyCheck,
    oneline: Credo.CLI.Command.Suggest.Output.Oneline,
    json: Credo.CLI.Command.Suggest.Output.Json,
    codeclimate: Credo.CLI.Command.Suggest.Output.Codeclimate

  alias Credo.CLI.Output.UI

  def print_help(exec) do
    usage = ["Usage: ", :olive, "mix credo suggest [paths] [options]"]

    description = """

    Suggests objects from every category that Credo thinks can be improved.
    """

    example = [
      "Example: ",
      :olive,
      :faint,
      "$ mix credo suggest lib/**/*.ex --all -c names"
    ]

    options = """

    Arrows (↑ ↗ → ↘ ↓) hint at the importance of an issue.

    Suggest options:
      -a, --all               Show all issues
      -A, --all-priorities    Show all issues including low priority ones
          --min-priority      Minimum priority to show issues (high,medium,normal,low,lower or number)
      -c, --checks            Only include checks that match the given strings
          --config-file       Use the given config file
      -C, --config-name       Use the given config instead of "default"
      -i, --ignore-checks     Ignore checks that match the given strings
          --format            Display the list in a specific format (oneline,flycheck,codeclimate)
          --mute-exit-status  Exit with status zero even if there are issues
          --include           Include files that match the given strings
          --exclude           Exclude files that match the given strings

    General options:
          --[no-]color        Toggle colored output
      -v, --version           Show version
      -h, --help              Show this help
    """

    UI.puts(usage)
    UI.puts(description)
    UI.puts(example)
    UI.puts(options)

    exec
  end
end
