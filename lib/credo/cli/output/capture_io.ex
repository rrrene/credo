defmodule Credo.CLI.Output.CaptureIO do
  @moduledoc false

  alias ExUnit.CaptureIO

  use Supervisor

  if Mix.env() == :test do
    # no need to start `ExUnit.CaptureServer` during tests, as it is already started
    @children []
  else
    @children [ExUnit.CaptureServer]
  end

  if Version.match?(System.version(), ">= 1.10.0-rc") do
    def children() do
      Enum.map(@children, &{&1, []})
    end
  else
    def children() do
      import Supervisor.Spec, warn: false
      Enum.map(@children, &worker(&1, []))
    end
  end

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    Supervisor.init(children(), strategy: :one_for_one)
  end

  def capture_stderr(fun), do: capture_io(:stderr, fun)
  def capture_stdout(fun), do: capture_io(:stdout, fun)

  defp capture_io(device, fun) do
    captured_output =
      CaptureIO.capture_io(device, fn ->
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
        {captured_output, {:ok, return_value}}
    end
  end
end
