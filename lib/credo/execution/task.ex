defmodule Credo.Execution.Task do
  @type t :: module

  @callback call(exec :: Credo.Execution.t, opts :: Keyword.t) :: Credo.Execution.t

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

  def run(exec, task, opts \\ [])
  def run(%Credo.Execution{halted: false} = exec, task, opts) do
    #require Logger
    #Logger.debug "Calling #{task} ..."

    case task.call(exec, opts) do
      %Credo.Execution{halted: false} = exec ->
        exec
      %Credo.Execution{halted: true} = exec ->
        task.error(exec, opts)
      value ->
        # TODO: improve message
        IO.warn "Expected task to return %Credo.Execution{}, got:"
        # credo:disable-for-next-line
        IO.inspect value

        value
    end
  end
  def run(exec, _task, _opts) do
    exec
  end
end
