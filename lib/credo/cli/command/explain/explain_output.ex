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
      "Examples:\n",
      :olive,
      "  $ mix credo explain lib/foo/bar.ex:13:6\n",
      "  $ mix credo explain lib/foo/bar.ex:13:6 --format json\n",
      "  $ mix credo explain Credo.Check.Refactor.Nesting"
    ]

    options =
      """

      Explain options:
            --format            Display the list in a specific format (json,flycheck,oneline)

      General options:
            --[no-]color        Toggle colored output
        -v, --version           Show version
        -h, --help              Show this help

      Find advanced usage instructions and more examples here:
        https://hexdocs.pm/credo/explain_command.html

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
