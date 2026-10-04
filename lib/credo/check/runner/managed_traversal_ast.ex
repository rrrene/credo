defmodule Credo.Check.Runner.ManagedTraversal.AST do
  alias Credo.Execution
  alias Credo.Check.Runner.ManagedTraversal

  def to_stream(exec, checks)

  def to_stream(_, nil), do: nil
  def to_stream(_, []), do: nil

  def to_stream(%Credo.Execution{} = exec, [_ | _] = check_tuples) do
    source_files = Execution.get_source_files(exec)
    filenames = Enum.map(source_files, & &1.filename)

    Task.async_stream(source_files, &run_source_file(exec, check_tuples, filenames, &1),
      timeout: :infinity,
      ordered: false
    )
  end

  defp run_source_file(exec, check_tuples, filenames, source_file) do
    managed_ctx = ManagedTraversal.build_context_for_all_checks(source_file, check_tuples, filenames)

    source_file
    |> Credo.Code.prewalk(&walk/2, managed_ctx)
    |> ManagedTraversal.append_issues_from_context_for_all(exec)
  end

  defp walk(ast, managed_ctx) do
    managed_ctx =
      Enum.reduce(managed_ctx, managed_ctx, fn
        {check, check_ctx}, inner_managed_ctx ->
          check_ctx =
            case check.handle_walk(ast, check_ctx) do
              %{__ctx: _} = check_ctx -> check_ctx
              {_ast, %{__ctx: _} = check_ctx} -> check_ctx
            end

          Map.put(inner_managed_ctx, check, check_ctx)
      end)

    {ast, managed_ctx}
  end
end
