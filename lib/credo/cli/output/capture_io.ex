defmodule Credo.CLI.Output.CaptureIO do
  @moduledoc false

  def capture_stderr(fun), do: capture_io(:stderr, fun)
  def capture_stdout(fun), do: capture_io(:stdout, fun)

  if Version.match?(System.version(), ">= 1.10.0-rc") do
    def initialize, do: Application.ensure_started(:ex_unit)

    defp capture_io(device, fun) do
      captured_output =
        ExUnit.CaptureIO.capture_io(device, fn ->
          return_value =
            try do
              fun.()
            catch
              kind, reason ->
                :erlang.raise(kind, reason, __STACKTRACE__)
            end

          send(self(), {:return_value, return_value})
        end)

      receive do
        {:return_value, return_value} ->
          {captured_output, return_value}
      end
    end
  else
    def initialize, do: nil

    defp capture_io(_device, fun), do: {"", fun.()}
  end
end
