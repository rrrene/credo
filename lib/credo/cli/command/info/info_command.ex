defmodule Credo.CLI.Command.Info.InfoCommand do
  @moduledoc false

  @shortdoc "Show useful debug information"

  use Credo.CLI.Command

  alias Credo.CLI.Command.Info.InfoOutput
  alias Credo.CLI.Task
  alias Credo.Execution

  @doc false
  def call(%Execution{help: true} = exec, _opts), do: InfoOutput.print_help(exec)

  def call(exec, _opts) do
    exec
    |> run_task(Task.LoadAndValidateSourceFiles)
    |> run_task(Task.PrepareChecksToRun)
    |> print_info()
  end

  defp print_info(exec) do
    InfoOutput.print(exec, info(exec))

    exec
  end

  defp info(exec) do
    %{
      "system" => %{
        "credo" => Credo.version(),
        "elixir" => System.version(),
        "erlang" => System.otp_release()
      },
      "config" => %{
        "checks" => checks(exec),
        "files" => files(exec)
      }
    }
  end

  defp checks(exec) do
    {checks, _only_matching, _ignore_matching} = Execution.checks(exec)

    Enum.map(checks, fn {name, _} -> name end)
  end

  defp files(exec) do
    exec
    |> Execution.get_source_files()
    |> Enum.map(& &1.filename)
  end
end
