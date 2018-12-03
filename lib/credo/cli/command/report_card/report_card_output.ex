defmodule Credo.CLI.Command.ReportCard.ReportCardOutput do
  @moduledoc false

  use Credo.CLI.Output.FormatDelegator,
    default: Credo.CLI.Command.ReportCard.Output.Console,
    console: Credo.CLI.Command.ReportCard.Output.Console,
    html: Credo.CLI.Command.ReportCard.Output.Html

  alias Credo.CLI.Output.UI

  def print_help(exec) do
    usage = ["Usage: ", :olive, "mix credo report_card [paths] [options]"]

    description = """

    Shows a report card for your modules based on Credo checks.
    """

    example = [
      "Example: ",
      :olive,
      :faint,
      "$ mix credo report_card lib/**/*.ex --format=html"
    ]

    options = """

    Report Card options:
      -a, --all               Show all issues
      -A, --all-priorities    Show all issues including low priority ones
          --min-priority      Minimum priority to show issues (high,medium,normal,low,lower or number)
      -c, --checks            Only include checks that match the given strings
          --config-file       Use the given config file
      -C, --config-name       Use the given config instead of "default"
      -i, --ignore-checks     Ignore checks that match the given strings
          --format            Display the list in a specific format (console,html)
          --mute-exit-status  Exit with status zero even if there are issues

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
