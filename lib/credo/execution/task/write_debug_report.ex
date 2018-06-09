defmodule Credo.Execution.Task.WriteDebugReport do
  use Credo.Execution.Task

  alias Credo.Execution.Timing
  alias Credo.CLI.Output.UI

  @debug_template_filename "debug-template.html"
  @debug_output_filename "credo-debug-log.html"

  def call(%Credo.Execution{debug: true} = exec, _opts) do
    Logger.flush()

    assigns = [exec: exec, timings: Timing.by_tag(exec, :check)]

    content = EEx.eval_file(@debug_template_filename, assigns: assigns)

    File.write!(@debug_output_filename, content)

    IO.puts(content)

    UI.puts([:green, "Debug log written to ", :reset, @debug_output_filename])

    exec
  end

  def call(exec, _opts) do
    exec
  end
end
