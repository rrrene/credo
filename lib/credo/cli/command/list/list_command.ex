defmodule Credo.CLI.Command.List.ListCommand do
  @moduledoc false

  use Credo.CLI.Command,
    short_description: "List all issues grouped by files",
    cli_switches: Credo.CLI.Command.Suggest.SuggestCommand.cli_switches()

  alias Credo.CLI.Command.List.ListOutput
  alias Credo.CLI.Filter
  alias Credo.CLI.Task
  alias Credo.Execution

  def init(exec) do
    Execution.put_pipeline(exec, "list",
      load_and_validate_source_files: [
        {Task.LoadAndValidateSourceFiles, []}
      ],
      prepare_analysis: [
        {Task.PrepareChecksToRun, []}
      ],
      print_before_analysis: [
        {__MODULE__.PrintBeforeInfo, []}
      ],
      run_analysis: [
        {Task.RunChecks, []}
      ],
      filter_issues: [
        {Task.SetRelevantIssues, []}
      ],
      print_after_analysis: [
        {__MODULE__.PrintResultsAndSummary, []}
      ]
    )
  end

  @doc false
  def call(%Execution{help: true} = exec, _opts), do: ListOutput.print_help(exec)
  def call(exec, _opts), do: Execution.run_pipeline(exec, __MODULE__)

  defmodule PrintBeforeInfo do
    @moduledoc false

    use Credo.Execution.Task

    def call(exec, _opts) do
      source_files =
        exec
        |> Execution.get_source_files()
        |> Filter.important(exec)

      ListOutput.print_before_info(source_files, exec)

      exec
    end
  end

  defmodule PrintResultsAndSummary do
    @moduledoc false

    use Credo.Execution.Task

    def call(exec, _opts) do
      source_files = Execution.get_source_files(exec)

      time_load = Execution.get_assign(exec, "credo.time.source_files")
      time_run = Execution.get_assign(exec, "credo.time.run_checks")

      ListOutput.print_after_info(source_files, exec, time_load, time_run)

      exec
    end
  end
end
