defmodule Credo.Check.Context do
  @moduledoc false

  alias Credo.Check.Params

  @doc false
  def build(source_file, params, check_mod, merge_map \\ %{}) do
    Map.merge(
      %{
        source_file: source_file,
        params: Params.get(params, check_mod),
        issues: []
      },
      merge_map
    )
  end

  @doc false
  def put_param(ctx, param_name, param_value) do
    Map.put(ctx, :params, Map.put(ctx.params, param_name, param_value))
  end

  @doc false
  def put_issue(ctx, nil), do: ctx
  def put_issue(ctx, []), do: ctx

  def put_issue(ctx, issues) when is_list(issues) do
    %{ctx | issues: issues ++ ctx.issues}
  end

  def put_issue(ctx, %Credo.Issue{} = issue) do
    %{ctx | issues: [issue | ctx.issues]}
  end

  @doc false
  def push(ctx, field, item) do
    list = Map.get(ctx, field, [])
    Map.put(ctx, field, [item | list])
  end
end
