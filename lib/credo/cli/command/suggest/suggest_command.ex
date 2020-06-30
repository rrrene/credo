defmodule Credo.CLI.Command.Suggest.SuggestCommand do
  @moduledoc false

  use Credo.CLI.Command

  @shortdoc "Suggest code objects to look at next (default)"

  alias Credo.CLI.Command.Suggest.SuggestOutput
  alias Credo.CLI.Task
  alias Credo.Execution

  def init(exec) do
    Execution.put_pipeline(exec, __MODULE__,
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

  def call(%Execution{help: true} = exec, _opts), do: SuggestOutput.print_help(exec)
  def call(exec, _opts), do: Execution.run_pipeline(exec, __MODULE__)

  defmodule PrintBeforeInfo do
    @moduledoc false

    use Credo.Execution.Task

    def call(exec, _opts) do
      source_files = Execution.get_source_files(exec)

      SuggestOutput.print_before_info(source_files, exec)

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

      SuggestOutput.print_after_info(source_files, exec, time_load, time_run)

      exec
    end
  end
end
