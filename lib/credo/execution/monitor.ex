defmodule Credo.Execution.Monitor do
  require Logger

  alias Credo.Execution.Timing

  def task(exec, task, opts, fun, args) do
    context_tuple = {:task, exec, task, opts}
    log(:call_start, context_tuple)

    {started_at, time, exec} = Timing.run(fun, args)

    log(:call_end, context_tuple, time)

    Timing.append(exec, [task: task, parent_task: exec.parent_task], started_at, time)

    exec
  end

  defp log(:call_start, {:task_group, _exec, task_group, _opts}) do
    Logger.info("Calling #{task_group} ...")
  end

  defp log(:call_start, {:task, _exec, task, _opts}) do
    Logger.info("Calling #{task} ...")
  end

  defp log(:call_start, context_tuple) do
    Logger.info("Calling #{inspect(context_tuple)} ...")
  end

  defp log(:call_end, {:task_group, _exec, task_group, _opts}, time) do
    Logger.info("Finished #{task_group} in #{format_time(time)} ...")
  end

  defp log(:call_end, {:task, _exec, task, _opts}, time) do
    Logger.info("Finished #{task} in #{format_time(time)} ...")
  end

  defp log(:call_end, context_tuple, time) do
    Logger.info("Finished #{inspect(context_tuple)} in #{format_time(time)} ...")
  end

  defp format_time(time) do
    cond do
      time > 1_000_000 ->
        "#{div(time, 1_000_000)}s"

      time > 1_000 ->
        "#{div(time, 1_000)}ms"

      true ->
        "#{time}μs"
    end
  end
end
