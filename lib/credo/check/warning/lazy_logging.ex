defmodule Credo.Check.Warning.LazyLogging do
  use Credo.Check,
    id: "EX5007",
    base_priority: :high,
    elixir_version: "< 1.7.0",
    param_defaults: [
      ignore: [:error, :warn, :info]
    ],
    explanations: [
      check: """
      Ensures laziness of Logger calls.

      You will want to wrap expensive logger calls into a zero argument
      function (`fn -> "string that gets logged" end`).

      Example:

          # preferred

          Logger.debug fn ->
            "This happened: \#{expensive_calculation(arg1, arg2)}"
          end

          # NOT preferred
          # the interpolation is executed whether or not the info is logged

          Logger.debug "This happened: \#{expensive_calculation(arg1, arg2)}"
      """,
      params: [
        ignore: "Do not raise an issue for these Logger calls."
      ]
    ]

  @logger_functions [:debug, :info, :warn, :error]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)
    # {<Logger import seen?>, <list of issues>}
    state = {false, []}

    {_, issues} = Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta), state)

    issues
  end

  defp traverse(
         {{:., _, [{:__aliases__, _, [:Logger]}, fun_name]}, meta, arguments} = ast,
         state,
         issue_meta
       )
       when fun_name in @logger_functions do
    issue = find_issue(fun_name, arguments, meta, issue_meta)

    {ast, add_issue_to_state(state, issue)}
  end

  defp traverse(
         {fun_name, meta, arguments} = ast,
         {true, _issues} = state,
         issue_meta
       )
       when fun_name in @logger_functions do
    issue = find_issue(fun_name, arguments, meta, issue_meta)

    {ast, add_issue_to_state(state, issue)}
  end

  defp traverse(
         {:import, _meta, arguments} = ast,
         {_module_contains_import?, issues} = state,
         _issue_meta
       ) do
    if logger_import?(arguments) do
      {ast, {true, issues}}
    else
      {ast, state}
    end
  end

  defp traverse(ast, state, _issue_meta) do
    {ast, state}
  end

  defp add_issue_to_state(state, nil), do: state

  defp add_issue_to_state({module_contains_import?, issues}, issue) do
    {module_contains_import?, [issue | issues]}
  end

  defp find_issue(fun_name, arguments, meta, issue_meta) do
    params = IssueMeta.params(issue_meta)
    ignored_functions = Params.get(params, :ignore, __MODULE__)

    unless Enum.member?(ignored_functions, fun_name) do
      issue_for_call(arguments, meta, fun_name, issue_meta)
    end
  end

  defp issue_for_call([{:<<>>, _, [_ | _]} | _] = _args, meta, fun_name, issue_meta) do
    issue_for(issue_meta, meta[:line], fun_name)
  end

  defp issue_for_call(_args, _meta, _trigger, _issue_meta) do
    nil
  end

  defp logger_import?([{:__aliases__, _meta, [:Logger]}]), do: true
  defp logger_import?(_), do: false

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message: "Prefer lazy Logger calls.",
      line_no: line_no,
      trigger: trigger
    )
  end
end
