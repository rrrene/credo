defmodule Credo.Check.Warning.UnusedOperation do
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
        [checked_module],
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
