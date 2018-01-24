defmodule Credo.CLI.Task.LoadAndValidateSourceFiles do
  use Credo.Execution.Task

  alias Credo.CLI.Output
  alias Credo.Sources

  def call(exec, _opts \\ []) do
    {time_load, {valid_source_files, invalid_source_files}} =
      :timer.tc(fn ->
        exec
        |> Sources.find()
        |> Credo.Backports.Enum.split_with(& &1.valid?)
      end)

    Output.complain_about_invalid_source_files(invalid_source_files)

    exec
    |> put_source_files(valid_source_files)
    |> put_assign("credo.time.source_files", time_load)
  end
end
