defmodule Credo.Execution.Task do
  @type t :: module

  @callback call(exec :: Credo.Execution.t, opts :: Keyword.t) :: Credo.Execution.t

  alias Credo.Execution

  defmacro __using__(_opts \\ []) do
    quote do
      @behaviour Credo.Execution.Task
      import Credo.Execution
      alias Credo.Execution

      def call(%Execution{halted: false} = exec, opts) do
        exec
      end

      def error(exec, _opts) do
        IO.warn "Execution halted during #{__MODULE__}!"
      end

      defoverridable call: 2
      defoverridable error: 2
    end
  end

  @doc """
  Runs a given `task` if the `Execution` wasn't halted and ensures that the
  result is also an `Execution` struct.
  """
  def run(exec, task, opts \\ [])
  def run(%Credo.Execution{halted: false} = exec, task, opts) do
    #require Logger
    #Logger.debug "Calling #{task} ..."

    case task.call(exec, opts) do
      %Execution{halted: false} = exec ->
        exec
      %Execution{halted: true} = exec ->
        task.error(exec, opts)
      value ->
        # TODO: improve message
        IO.warn "Expected task to return %Credo.Execution{}, got:"
        # credo:disable-for-next-line
        IO.inspect value

        value
    end
  end
  def run(%Execution{} = exec, _task, _opts) do
    exec
  end
  def run(exec, _task, _opts) do
    IO.warn "Expected first parameter of Task.run/3 to match %Credo.Execution{}, got: #{inspect(exec)}"

    exec
  end
end
