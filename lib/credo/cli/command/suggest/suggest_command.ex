defmodule Credo.CLI.Command.Suggest.SuggestCommand do
  @moduledoc false

  alias Credo.Check.Params
  alias Credo.CLI.Command.Suggest.SuggestOutput
  alias Credo.CLI.Switch
  alias Credo.CLI.Task
  alias Credo.Execution

  use Credo.CLI.Command,
    short_description: "Suggest code objects to look at next (default)",
    cli_switches: [
      Switch.boolean("all_priorities", alias: :A),
      Switch.boolean("all", alias: :a),
      Switch.boolean("crash_on_error"),
      Switch.keep("files_included"),
      Switch.keep("files_excluded"),
      Switch.keep("checks_with_tag"),
      Switch.keep("checks_without_tag"),
      Switch.string("checks", alias: :c),
      Switch.string("enable_disabled_checks"),
      Switch.string("min_priority"),
      Switch.boolean("mute_exit_status"),
      Switch.boolean("first_run"),
      Switch.string("format"),
      Switch.boolean("help", alias: :h),
      Switch.string("ignore_checks"),
      Switch.string("ignore", alias: :i),
      Switch.string("only"),
      Switch.boolean("read_from_stdin"),
      Switch.boolean("strict"),
      Switch.boolean("verbose"),
      Switch.boolean("watch")
    ]

  def init(exec) do
    Execution.put_pipeline(exec, "suggest",
      load_and_validate_source_files: [Task.LoadAndValidateSourceFiles],
      prepare_analysis: [Task.PrepareChecksToRun],
      __manipulate_config_if_rerun__: [__MODULE__.ManipulateConfigIfRerun],
      print_before_analysis: [__MODULE__.PrintBeforeInfo],
      run_analysis: [Task.RunChecks],
      filter_issues: [Task.SetRelevantIssues],
      print_after_analysis: [__MODULE__.PrintResultsAndSummary]
    )
  end

  def call(%Execution{help: true} = exec, _opts), do: SuggestOutput.print_help(exec)
  def call(exec, _opts), do: Execution.run_pipeline(exec, __MODULE__)

  defmodule PrintBeforeInfo do
    @moduledoc false

    use Credo.Execution.Task

    def call(exec) do
      source_files = Execution.get_source_files(exec)

      SuggestOutput.print_before_info(source_files, exec)

      exec
    end
  end

  defmodule PrintResultsAndSummary do
    @moduledoc false

    use Credo.Execution.Task

    def call(exec) do
      source_files = Execution.get_source_files(exec)

      time_load = Execution.get_assign(exec, "credo.time.source_files")
      time_run = Execution.get_assign(exec, "credo.time.run_checks")

      SuggestOutput.print_after_info(source_files, exec, time_load, time_run)

      exec
    end
  end

  defmodule ManipulateConfigIfRerun do
    @moduledoc false

    use Credo.Execution.Task

    def call(exec, _opts) do
      case Execution.get_rerun(exec) do
        :notfound ->
          exec

        {previous_exec, files_that_changed} ->
          exec
          |> selectively_transfer_issues_from_previous_exec(previous_exec, files_that_changed)
          |> modify_config_to_only_include_needed_checks(files_that_changed)
      end
    end

    def selectively_transfer_issues_from_previous_exec(exec, previous_exec, files_that_changed) do
      issues_to_keep =
        previous_exec
        |> Execution.get_issues()
        |> Enum.reject(fn issue ->
          issue.category == :consistency ||
            Enum.member?(files_that_changed, issue.filename)
        end)

      # all checks on `files_that_changed`
      # consistency checks on all files

      Execution.put_issues(exec, issues_to_keep)
    end

    def modify_config_to_only_include_needed_checks(%Credo.Execution{} = exec, files_that_changed) do
      checks =
        Enum.map(exec.checks, fn {check, params} ->
          if check.category == :consistency do
            {check, params}
          else
            {check, Params.put_rerun_files_that_changed(params, files_that_changed)}
          end
        end)

      %Execution{exec | checks: checks}
    end
  end
end
