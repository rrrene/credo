defmodule Credo.CLI.Command.Explain.ExplainOutput do
  @moduledoc false

  alias Credo.CLI.Output.UI

  use Credo.CLI.Output.FormatDelegator,
    default: Credo.CLI.Command.Explain.Output.Default,
    json: Credo.CLI.Command.Explain.Output.Json

  def print_help(exec) do
    usage = [
      "Usage: ",
      :olive,
      "mix credo explain <check_name_or_path_line_no_column> [options]"
    ]

    description = """

    Explain the given check or issue.
    """

    example = [
      "Example: ",
      :olive,
      :faint,
      "$ mix credo explain lib/foo/bar.ex:13:6"
    ]

    example2 = [
      "         ",
      :olive,
      :faint,
      "$ mix credo explain Credo.Check.Refactor.Nesting"
    ]

    options = """

    General options:
          --[no-]color        Toggle colored output
      -v, --version           Show version
      -h, --help              Show this help
    """

    UI.puts(usage)
    UI.puts(description)
    UI.puts(example)
    UI.puts(example2)
    UI.puts(options)

    exec
  end
end
