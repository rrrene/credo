defmodule Credo.CLI.Command.GenCheck do
  use Credo.CLI.Command

  @shortdoc "Create a new custom check"

  @check_template_filename ".template.check.ex"
  @default_check_template_file File.read!(@check_template_filename)

  def run(args, _config) do
    args
    |> List.first
    |> create_check_file
  end

  defp create_check_file(nil) do
    [:red, :bright, "Please provide a filename:", "\n\n",
      "  mix credo gen.check lib/my_first_credo_check.ex", "\n"]
    |> Bunt.puts
  end
  defp create_check_file(filename) do
    check_name = check_name_for(filename)

    if File.exists?(filename) do
      Bunt.puts [:red, :bright, "File exists: #{filename}, aborted."]
    else
      write_template_file(filename, check_name)
      Bunt.puts [:green, "* creating ", :reset, "#{filename}"]
      Bunt.puts
      print_config_instructions(filename, check_name)
    end

    :ok
  end

  def check_name_for(filename) do
    filename
    |> String.replace(~r/(\A|(.+)\/)(lib|web)\//, "")
    |> String.replace(~r/\.ex$/, "")
    |> Macro.camelize
    |> String.replace(~r/\_/, "")
  end

  defp write_template_file(filename, check_name) do
    filename
    |> Path.dirname
    |> File.mkdir_p!

    assigns = [check_name: check_name]
    contents = EEx.eval_string(@default_check_template_file, assigns: assigns)
    File.write!(filename, contents)
  end

  defp print_config_instructions(filename, check_name) do
    Bunt.puts "Add the generated file to the list of `requires` in `.credo.exs`:"
    Bunt.puts
    Bunt.puts ["    requires: [", :green, "\"", filename, "\"", :reset, "], ", :faint, "# <-- add file here"]
    Bunt.puts
    Bunt.puts "Remember to add the generated module to the list of `checks`:"
    Bunt.puts
    Bunt.puts ["    checks: ["]
    Bunt.puts ["      {", :green, check_name, :reset, "}, ", :faint, "# <-- add check here"]
    Bunt.puts ["    ]"]
    Bunt.puts
    Bunt.puts ["If you do not have a config file yet, use `mix credo gen.config`"]
  end

end
