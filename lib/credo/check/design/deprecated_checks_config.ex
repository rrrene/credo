defmodule Credo.Check.Design.DeprecatedChecksConfig do
  use Credo.Check,
    id: "EX2008",
    base_priority: :normal,
    param_defaults: [],
    explanations: [
      check: """
      Checks for an old `.credo.exs` config file format regarding checks.

      Instead of using a list for checks and deactivating them by setting the params to `false`:

          %{
            configs: [
              %{
                name: "default",
                checks: [
                  # ...
                  {Credo.Check.Readability.LargeNumbers, false}
                ]
              }
            ]
          }

      Use a map with `:enabled` and `:disabled` keys. This way, the check's params get preserved:

          %{
            configs: [
              %{
                name: "default",
                checks: %{
                  enabled: [
                    # ...
                  ],
                  diabled: [
                    {Credo.Check.Readability.LargeNumbers, only_greater_than: 99_999}
                  ]
                }
              }
            ]
          }
      """,
      params: []
    ]

  @doc false
  def run_on_all_source_files(%Execution{} = exec, _source_files, params) do
    ctx = Context.build(source_file_stub(), params, __MODULE__)

    exec
    |> find_missing_checks(ctx)
    |> append_issues_and_timings(exec)

    :ok
  end

  defp find_missing_checks(exec, ctx) do
    case Execution.get_assign(exec, "credo.validated_config") do
      %{checks: check_map} when is_list(check_map) ->
        [issue_for(ctx, "Using a list for `:checks` in Credo's config is deprecated, use a map instead.")]

      %{checks: check_map} when is_map(check_map) ->
        (List.wrap(check_map[:enabled]) ++ List.wrap(check_map[:disabled]))
        |> Enum.flat_map(fn
          {check, false} ->
            [
              issue_for(
                ctx,
                "Using `false` for deactivating check `#{inspect(check)}` in Credo's config is deprecated, move them to `:disabled` instead."
              )
            ]

          {_check, _params} ->
            []
        end)

      _ ->
        []
    end
  end

  @doc false
  def source_file_stub() do
    %SourceFile{filename: ".credo.exs"}
  end

  defp issue_for(ctx, message) do
    issue =
      format_issue(ctx,
        message: message,
        line_no: 1,
        trigger: Issue.no_trigger()
      )

    %{issue | scope: "config"}
  end
end
