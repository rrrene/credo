defmodule Credo.Execution.Timing do
  defmacro span(exec, name, tags, do: block) do
    quote do
      case unquote(exec) do
        %{config: %{debug: true}} = exec ->
          Credo.Execution.Timing.record_span(exec, unquote(name), unquote(tags), fn ->
            unquote(block)
          end)

        _ ->
          unquote(block)
      end
    end
  end

  defmacro add_event(exec, event_name, attributes \\ quote(do: %{})) do
    quote do
      case unquote(exec) do
        %{config: %{debug: true}} = exec ->
          Credo.Execution.Timing.record_event(exec, unquote(event_name), unquote(attributes))

        exec ->
          exec
      end
    end
  end

  @doc false
  def record_span(exec, name, tags, fun) do
    started_at = now()
    parent_span_ctx = get_span_ctx(exec)
    parent_span_id = parent_span_ctx.span_id

    span_id =
      if parent_span_id do
        generate_span_id()
      else
        <<0, 0, 0, 0, 0, 0, 0, 0>>
      end

    exec =
      set_span_ctx(exec, %{
        span_id: span_id,
        parent_span_id: parent_span_id,
        events: []
      })

    {duration, result} = :timer.tc(fun)

    span_ctx = get_span_ctx()

    Credo.Execution.ExecutionTiming.append(
      exec,
      span_ctx,
      name,
      tags,
      started_at,
      duration
    )

    set_span_ctx(exec, parent_span_ctx)

    result
  end

  @doc false
  def record_event(%Credo.Execution{} = exec, event_name, attributes \\ %{}) do
    span_ctx = get_span_ctx(exec)

    event = %{
      name: event_name,
      time: now(),
      attributes: attributes
    }

    set_span_ctx(exec, %{span_ctx | events: [event | span_ctx.events]})

    exec
  end

  def now, do: :os.system_time(:microsecond)

  def get_span_ctx(%{private: %{span_ctx: span_ctx}}) do
    span_ctx || get_span_ctx()
  end

  def get_span_ctx do
    Process.get(:credo_span_ctx, %{span_id: nil, parent_span_id: nil})
  end

  def set_span_ctx(exec, span_ctx) do
    Credo.Execution.put_private(exec, :span_ctx, set_span_ctx(span_ctx))
  end

  def set_span_ctx(span_ctx) do
    Process.put(:credo_span_ctx, span_ctx)

    span_ctx
  end

  def generate_span_id do
    case :crypto.strong_rand_bytes(8) do
      <<0, 0, 0, 0, 0, 0, 0, 0>> -> generate_span_id()
      id -> id
    end
  end
end
