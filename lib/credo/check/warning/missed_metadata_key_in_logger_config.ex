defmodule Credo.Check.Warning.MissedMetadataKeyInLoggerConfig do
  use Credo.Check,
    id: "EX5027",
    base_priority: :high,
    category: :warning,
    param_defaults: [
      metadata_keys: []
    ],
    explanations: [
      check: """
      Ensures custom metadata keys are included in logger config

      Note that all metadata is optional and may not always be available.

      For example, you might wish to include a custom `:error_code` metadata in your logs:

          Logger.error("We have a problem", [error_code: :pc_load_letter])

      In your app's logger configuration, you would need to include the `:error_code` key:

          config :logger, :console,
            format: "[$level] $message $metadata\n",
            metadata: [:error_code, :file]

      That way your logs might then receive lines like this:

          [error] We have a problem error_code=pc_load_letter file=lib/app.ex
      """,
      params: [
        ignore_logger_functions: "Do not raise an issue for these Logger functions.",
        metadata_keys: """
        Do not raise an issue for these Logger metadata keys.

        By default, we assume the metadata keys listed under your `console`
        backend.
        """
      ]
    ]

  @logger_functions ~w(alert critical debug emergency error info notice warn warning metadata log)a

  @doc false
  @impl Credo.Check
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)
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
    metadata_keys = find_metadata_keys(params)

    issue_for_call(fun_name, arguments, meta, issue_meta, metadata_keys)
  end

  defp issue_for_call(:metadata, [logger_metadata], meta, issue_meta, metadata_keys) do
    issue_for_call(logger_metadata, meta, issue_meta, metadata_keys)
  end

  defp issue_for_call(:log, [_, _, logger_metadata], meta, issue_meta, metadata_keys) do
    issue_for_call(logger_metadata, meta, issue_meta, metadata_keys)
  end

  defp issue_for_call(:log, _args, _meta, _issue_meta, _metadata_keys) do
    nil
  end

  defp issue_for_call(_fun_name, [_, logger_metadata] = _args, meta, issue_meta, metadata_keys) do
    issue_for_call(logger_metadata, meta, issue_meta, metadata_keys)
  end

  defp issue_for_call(_fun_name, _args, _meta, _issue_meta, _metadata_keys) do
    nil
  end

  defp issue_for_call(logger_metadata, meta, issue_meta, metadata_keys) do
    if Keyword.keyword?(logger_metadata) do
      case Keyword.drop(logger_metadata, metadata_keys) do
        [] ->
          nil

        missed ->
          issue_for(issue_meta, meta[:line], Keyword.keys(missed))
      end
    end
  end

  defp logger_import?([{:__aliases__, _meta, [:Logger]}]), do: true
  defp logger_import?(_), do: false

  defp issue_for(issue_meta, line_no, missed_keys) do
    message = "Logger metadata key #{Enum.join(missed_keys, ", ")} will be ignored in production"

    format_issue(issue_meta, message: message, line_no: line_no)
  end

  defp find_metadata_keys(params) do
    metadata_keys = Params.get(params, :metadata_keys, __MODULE__)

    if metadata_keys == [] do
      :logger |> Application.get_env(:console, []) |> Keyword.get(:metadata, [])
    else
      metadata_keys
    end
  end
end
