defmodule Credo.CLI.Command.Explain.ExplainOutput do
  alias Credo.CLI.Output.UI

  alias Credo.CLI.Command.Explain.Output.Default

  def print_before_info(source_files, exec) do
    output_mod(exec).print_before_info(source_files, exec)
  end

  def print_after_info(source_file, exec, line_no, column) do
    output_mod(exec).print_after_info(source_file, exec, line_no, column)
  end

  defp output_mod(_exec), do: Default

  def print_help(exec) do
    usage = [
      "Usage: ",
      :olive,
      "mix credo explain path_line_no_column [options]"
    ]

    description = """

    Explain the given issue.
    """

    example = [
      "Example: ",
      :olive,
      :faint,
      "$ mix credo explain lib/foo/bar.ex:13:6"
    ]

    options = """

    General options:
      -v, --version       Show version
      -h, --help          Show this help
    """

    UI.puts(usage)
    UI.puts(description)
    UI.puts(example)
    UI.puts(options)

    exec
  end
end
