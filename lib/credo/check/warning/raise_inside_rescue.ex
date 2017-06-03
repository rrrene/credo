defmodule Credo.Check.Warning.RaiseInsideRescue do
  @moduledoc """
  Using `Kernel.raise` inside of a `rescue` block creates a new stacktrace,
  which obscures the cause of the original error.

  Example:

      # Prefer

      try do
        raise "oops"
      rescue
        e ->
          stacktrace = System.stacktrace # get the stacktrace of the exception
          Logger.warn("An exception has occurred")
          reraise e, stacktrace
      end

      # to

      try do
        raise "oops"
      rescue
        e ->
          Logger.warn("An exception has occurred")
          raise e
      end
  """

  @explanation [check: @moduledoc]

  use Credo.Check
  alias Credo.Code.Block

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse({:try, _meta, _arguments} = ast, issues, issue_meta) do
    case Block.rescue_block_for(ast) do
      {:ok, branches} ->
        issues_found =
          branches
          |> Enum.map(&extract_block/1)
          |> List.foldr([], &issue_for_block(&1, &2, issue_meta))
        {ast, issues ++ issues_found}
      :otherwise ->
        {ast, issues}
    end
  end
  defp traverse(ast, issues, _issue_meta), do: {ast, issues}

  defp extract_block({:->, _m, [_binding, {:__block__, _b_m, block}]}), do: block
  defp extract_block(_), do: []

  defp issue_for_block(block, issues, issue_meta) do
    issue = Enum.find_value(block, fn
      {:raise, raise_meta, _arguments} ->
        issue_for(raise_meta, issue_meta)
      _ ->
        nil
    end)

    case issue do
      nil -> issues
      issue -> [issue | issues]
    end
  end

  defp issue_for(raise_meta, issue_meta) do
    format_issue issue_meta,
      message: "Use reraise inside a rescue block to preserve the original stacktrace.",
      trigger: "raise",
      line_no: raise_meta[:line]
  end
end
