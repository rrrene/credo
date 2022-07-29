defmodule Credo.Execution.Task.WriteDebugReport do
  @moduledoc false

  @debug_template File.read!(".template.debug.html")
  @debug_output_filename "credo-debug-log.html"

  use Credo.Execution.Task

  alias Credo.CLI.Output.UI
  alias Credo.Execution.ExecutionTiming

  def call(%Credo.Execution{debug: true} = exec, _opts) do
    Logger.flush()

    time_load = exec |> get_assign("credo.time.source_files", 0) |> div(1000)
    time_run = exec |> get_assign("credo.time.run_checks", 0) |> div(1000)
    time_total = time_load + time_run

    all_timings = ExecutionTiming.all(exec)
    started_at = ExecutionTiming.started_at(exec)
    ended_at = ExecutionTiming.ended_at(exec)
    all_timings = timings_to_map(all_timings)

    file_timings =
      all_timings
      |> Enum.reduce(%{}, fn element, acc ->
        if filename = element.tags[:filename] do
          Map.put(acc, filename, (acc[filename] || 0) + element.duration)
        else
          acc
        end
      end)
      |> Enum.sort_by(&elem(&1, 1))
      |> Enum.reverse()

    check_timings =
      all_timings
      |> Enum.reduce(%{}, fn element, acc ->
        if check = element.tags[:check] do
          Map.put(acc, check, (acc[check] || 0) + element.duration)
        else
          acc
        end
      end)
      |> Enum.sort_by(&elem(&1, 1))
      |> Enum.reverse()

    check_file_timings =
      all_timings
      |> Enum.reduce(%{}, fn element, acc ->
        filename = element.tags[:filename]
        check = element.tags[:check]

        if filename && check do
          Map.put(acc, {check, filename}, (acc[{check, filename}] || 0) + element.duration)
        else
          acc
        end
      end)
      |> Enum.sort_by(&elem(&1, 1))
      |> Enum.reverse()

    assigns = [
      exec: exec,
      started_at: started_at,
      ended_at: ended_at,
      duration: ended_at - started_at,
      time_total: time_total,
      time_load: time_load,
      time_run: time_run,
      all_timings: all_timings,
      file_timings: file_timings,
      check_timings: check_timings,
      check_file_timings: check_file_timings
    ]

    content = EEx.eval_string(@debug_template, assigns: assigns)

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
