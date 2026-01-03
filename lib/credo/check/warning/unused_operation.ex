defmodule Credo.Check.Warning.UnusedOperation do
  use Credo.Check,
    id: "EX5019",
    base_priority: :high,
    explanations: [
      check: """
      The result of a call to some functions has to be used.

      This is a generic check that you can configure to your needs.

      While this is correct ...

          def clean_and_verify_options!(map) do
            map = Map.delete(map, :debug)

            if Enum.length(map) == 0, do: raise "OMG!!!1"

            map
          end

      ... we forgot to save the result in this example:

          def clean_and_verify_options!(map) do
            Map.delete(map, :debug)

            if Enum.length(map) == 0, do: raise "OMG!!!1"

            map
          end

      Most operations never work on the variable you pass in, but return a new
      variable which has to be used somehow.
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)

    ctx = %{ctx | params: normalize_params(ctx.params)}

    Enum.flat_map(ctx.params.modules, fn {mod, fun_list, issue_message} ->
      issues = run(source_file, params, mod, fun_list, &format_issue/2)

      case issue_message do
        "" <> message -> Enum.map(issues, fn issue -> %{issue | message: message} end)
        nil -> issues
      end
    end)
  end

  defp normalize_params(params) do
    modules =
      Enum.map(params.modules, fn
        {mod, fun_list} -> {normalize_mod(mod), fun_list, nil}
        {mod, fun_list, issue_message} -> {normalize_mod(mod), fun_list, issue_message}
      end)

    Map.put(params, :modules, modules)
  end

  defp normalize_mod(mod) do
    mod
  end

  # The result of a call to the provided module's functions has to be used.

  alias Credo.Check.Warning.UnusedFunctionReturnHelper
  alias Credo.IssueMeta

  @doc false
  def run(source_file, params \\ [], checked_module, funs_with_return_value, format_issue_fun) do
    issue_meta = IssueMeta.for(source_file, params)

    relevant_funs =
      if params[:ignore] do
        ignored_funs = List.wrap(params[:ignore])

        funs_with_return_value -- ignored_funs
      else
        funs_with_return_value
      end

    all_unused_calls =
      UnusedFunctionReturnHelper.find_unused_calls(
        source_file,
        params,
        List.wrap(checked_module),
        relevant_funs
      )

    Enum.reduce(all_unused_calls, [], fn invalid_call, issues ->
      {{:., _, [{:__aliases__, meta, _}, _fun_name]}, _, _} = invalid_call

      trigger =
        invalid_call
        |> Macro.to_string()
        |> String.split("(")
        |> List.first()

      [issue_for(format_issue_fun, issue_meta, meta, trigger, checked_module) | issues]
    end)
  end

  defp issue_for(format_issue_fun, issue_meta, meta, trigger, checked_module) do
    format_issue_fun.(
      issue_meta,
      message: "There should be no unused return values for #{checked_module} functions.",
      trigger: trigger,
      line_no: meta[:line],
      column: meta[:column]
    )
  end
end
