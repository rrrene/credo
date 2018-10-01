defmodule Credo.CLI.Command.GenCheck do
  @moduledoc false

  @shortdoc "Create a new custom check"

  @check_template_filename ".template.check.ex"
  @default_check_template_file File.read!(@check_template_filename)

  use Credo.CLI.Command

  alias Credo.CLI.Output.UI

  @doc false
  def call(exec, _opts) do
    exec.cli_options.args
    |> List.first()
    |> create_check_file

    exec
  end

  defp create_check_file(nil) do
    output = [
      :red,
      :bright,
      "Please provide a filename:",
      "\n\n",
      "  mix credo gen.check lib/my_first_credo_check.ex",
      "\n"
    ]

    UI.puts(output)
  end

  defp create_check_file(filename) do
    check_name = check_name_for(filename)

    if File.exists?(filename) do
      UI.puts([:red, :bright, "File exists: #{filename}, aborted."])
    else
      write_template_file(filename, check_name)

      UI.puts([:green, "* creating ", :reset, "#{filename}"])
      UI.puts()

      print_config_instructions(filename, check_name)
    end
  end

  def check_name_for(filename) do
    filename
    |> String.replace(~r/(\A|(.+)\/)(lib|web)\//, "")
    |> String.replace(~r/\.ex$/, "")
    |> Macro.camelize()
    |> String.replace(~r/\_/, "")
  end

  defp write_template_file(filename, check_name) do
    filename
    |> Path.dirname()
    |> File.mkdir_p!()

    assigns = [check_name: check_name]
    contents = EEx.eval_string(@default_check_template_file, assigns: assigns)

    File.write!(filename, contents)
  end

  defp print_config_instructions(filename, check_name) do
    UI.puts("Add the generated file to the list of `requires` in `.credo.exs`:")
    UI.puts()

    UI.puts([
      "    requires: [",
      :green,
      "\"",
      filename,
      "\"",
      :reset,
      "], ",
      :faint,
      "# <-- add file here"
    ])

    UI.puts()
    UI.puts("Remember to add the generated module to the list of `checks`:")
    UI.puts()
    UI.puts(["    checks: ["])

    UI.puts([
      "      {",
      :green,
      check_name,
      :reset,
      "}, ",
      :faint,
      "# <-- add check here"
    ])

    UI.puts(["    ]"])
    UI.puts()
    UI.puts(["If you do not have a exec file yet, use `mix credo gen.config`"])
  end
end
