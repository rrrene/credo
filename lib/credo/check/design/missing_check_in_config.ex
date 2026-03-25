defmodule Credo.Check.Design.MissingCheckInConfig do
  use Credo.Check,
    id: "EX2007",
    base_priority: :high,
    param_defaults: [
      compare_to: :all
    ],
    explanations: [
      check: """
      Knowing if a Credo config covers all existing checks can be difficult,
      especially over time, when new checks are introduced.

      Enabling/disabling all relevant checks explicitly can help staying on top of this.
      """,
      params: [
        compare_to: """
        Which set of checks should be considered when looking for missing checks:

        - `:all` - all checks
        - `:credo_checks` - all checks from Credo
        - `:credo_checks_enabled_by_default` - all checks from Credo that are enabled by default
        """
      ]
    ]

  @doc false
  def run_on_all_source_files(%Execution{} = exec, _source_files, params) do
    ctx = Context.build(source_file_stub(), params, __MODULE__)

    exec
    |> find_missing_checks(ctx)
    |> Enum.map(&issue_for(ctx, &1))
    |> append_issues_and_timings(exec)

    :ok
  end

  defp find_missing_checks(exec, ctx) do
    case Execution.get_assign(exec, "credo.validated_config") do
      %{checks: check_map} ->
        configured_checks =
          (List.wrap(check_map[:enabled]) ++ List.wrap(check_map[:disabled]))
          |> Enum.map(&elem(&1, 0))

        all_relevant_checks = checks_to_compare_with(ctx.params.compare_to)

        all_relevant_checks -- configured_checks

      _ ->
        []
    end
  end

  defp checks_to_compare_with(:all) do
    Credo.Check.all_loaded_checks()
  end

  defp checks_to_compare_with(:credo_checks) do
    Credo.Check.standard_checks()
  end

  defp checks_to_compare_with(:credo_checks_enabled_by_default) do
    Credo.Check.standard_checks()
  end

  @doc false
  def source_file_stub() do
    %SourceFile{filename: ".credo.exs"}
  end

  defp issue_for(ctx, check) do
    issue =
      format_issue(ctx,
        message: "Check `#{inspect(check)}` missing in config: enable or disable it explicitly.",
        trigger: Issue.no_trigger()
      )

    %{issue | scope: "config"}
  end
end
