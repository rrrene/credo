defmodule Credo.Execution.Task.WriteDebugReport do
  use Credo.Execution.Task

  alias Credo.Execution.Timing
  alias Credo.CLI.Output.UI

  @debug_template_filename "debug-template.html"
  @debug_output_filename "credo-debug-log.html"

  def call(%Credo.Execution{debug: true} = exec, _opts) do
    Logger.flush()

    time_load = exec |> get_assign("credo.time.source_files") |> div(1000)
    time_run = exec |> get_assign("credo.time.run_checks") |> div(1000)
    time_total = time_load + time_run

    all_timings = Timing.all(exec)
    started_at = Timing.started_at(exec)
    ended_at = Timing.ended_at(exec)

    assigns = [
      exec: exec,
      started_at: started_at,
      ended_at: ended_at,
      duration: ended_at - started_at,
      all_timings: timings_to_map(all_timings),
      time_total: time_total,
      time_load: time_load,
      time_run: time_run
    ]

    content = EEx.eval_file(@debug_template_filename, assigns: assigns)

    File.write!(@debug_output_filename, content)

    UI.puts([:green, "Debug log written to ", :reset, @debug_output_filename])

    exec
  end

  def call(exec, _opts) do
    exec
  end

  def timings_to_map(list) do
    Enum.map(list, fn {tags, started_at, duration} ->
      %{tags: Enum.into(tags, %{}), started_at: started_at, duration: duration}
    end)
  end
end
