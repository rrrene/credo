defmodule Credo do
  @moduledoc """
  Credo builds upon four building blocks:

  - `Credo.CLI` - everything related to the command line interface (CLI), which orchestrates the analysis
  - `Credo.Execution` - a struct which is handed down the pipeline during analysis
  - `Credo.Check` - the default Credo checks
  - `Credo.Code` - all analysis tools used by Credo during analysis
  """

  alias Credo.Execution
  alias Credo.Execution.Task.WriteDebugReport

  @version Mix.Project.config()[:version] |> Credo.BuildInfo.version()

  @doc """
  Runs Credo with the given `argv` and returns its final `Credo.Execution` struct.

  Example:

      iex> exec = Credo.run(["--only", "Readability"])
      iex> issues = Credo.Execution.get_issues(exec)
      iex> Enum.count(issues) > 0
      true

  """
  def run(argv_or_exec) do
    argv_or_exec
    |> Execution.build()
    |> Execution.run()
    |> WriteDebugReport.call([])
  end

  def run(argv_or_exec, files_that_changed) do
    argv_or_exec
    |> Execution.build(files_that_changed)
    |> Execution.run()
    |> WriteDebugReport.call([])
  end

  def version, do: @version
end
