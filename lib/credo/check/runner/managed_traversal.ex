defmodule Credo.Check.Runner.ManagedTraversal do
  alias Credo.Check.Params

  def build_context_for_all_checks(source_file, check_tuples, filenames) do
    check_tuples
    |> Enum.filter(&run_check_for_file?(&1, source_file.filename, filenames))
    |> Enum.map(fn {check, params} ->
      {check, check.build_context(source_file, params)}
    end)
    |> Map.new()
  end

  def append_issues_from_context_for_all(ctx, exec) do
    issues = Enum.flat_map(ctx, fn {check, %{__ctx: _} = check_ctx} -> check.issues_from_context(check_ctx) end)

    Credo.Execution.ExecutionIssues.append(exec, issues)
  end

  defp run_check_for_file?({check, params}, filename, known_files) do
    files_included = Params.files_included(params, check, known_files)
    files_excluded = Params.files_excluded(params, check)

    file_included? =
      if files_included != known_files do
        Credo.Sources.filename_matches?(filename, files_included)
      else
        true
      end

    file_excluded? =
      if files_excluded != [] do
        Credo.Sources.filename_matches?(filename, files_excluded)
      else
        false
      end

    file_included? && !file_excluded?
  end
end
