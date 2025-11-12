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
      Ensures custom metadata keys are included in logger config.

      Note that all metadata is optional and may not always be available.

      For example, you might wish to include a custom `:error_code` metadata in your logs:

          Logger.error("We have a problem", [error_code: :pc_load_letter])

      In your app's logger configuration, you would need to include the `:error_code` key:

          config :logger, :default_formatter,
            format: "[$level] $message $metadata\\n",
            metadata: [:error_code, :file]

      That way your logs might then receive lines like this:

          [error] We have a problem error_code=pc_load_letter file=lib/app.ex

      If you want to allow any metadata to be printed, you can use `:all` in the logger's
      metadata config.
      """,
      params: [
        metadata_keys: """
        Do not raise an issue for these Logger metadata keys.

        By default, we read the metadata keys configured as the current environment's
        `:default_formatter` (or `:console` for older versions of Elixir).

        You can use this parameter to dynamically load the environment/backend you care about,
        via `.credo.exs` (e.g. reading the `:file_log` config from `config/prod.exs`):

            {Credo.Check.Warning.MissedMetadataKeyInLoggerConfig,
              [
                metadata_keys:
                  "config/prod.exs"
                  |> Config.Reader.read!()
                  |> get_in([:logger, :file_log, :metadata])
              ]}
        """
      ]
    ]

  @logger_functions ~w(alert critical debug emergency error info notice warn warning metadata log)a
  @native_logger_metadata_keys [:ansi_color, :report_cb]

  @doc false
  @impl Credo.Check
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__, %{module_contains_import: false})

    metadata_keys = find_metadata_keys(ctx.params.metadata_keys)
    ignore_check? = metadata_keys == :all

    if ignore_check? do
      []
    else
      ctx = put_param(ctx, :metadata_keys, metadata_keys ++ @native_logger_metadata_keys)

      result = Credo.Code.prewalk(source_file, &walk/2, ctx)
      result.issues
    end
  end

  defp walk({{:., _, [{:__aliases__, _, [:Logger]}, fun_name]}, meta, arguments} = ast, ctx)
       when fun_name in @logger_functions do
    issue = issue_for_call(fun_name, arguments, meta, ctx)

    {ast, put_issue(ctx, issue)}
  end

  defp walk({fun_name, meta, arguments} = ast, %{module_contains_import: true} = ctx)
       when fun_name in @logger_functions do
    issue = issue_for_call(fun_name, arguments, meta, ctx)

    {ast, put_issue(ctx, issue)}
  end

  defp walk({:import, _, [{:__aliases__, _, [:Logger]}]} = ast, ctx) do
    {ast, %{ctx | module_contains_import: true}}
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp issue_for_call(:metadata, [logger_metadata], meta, ctx) do
    issue_for_call(logger_metadata, meta, ctx)
  end

  defp issue_for_call(:log, [_, _, logger_metadata], meta, ctx) do
    issue_for_call(logger_metadata, meta, ctx)
  end

  defp issue_for_call(:log, _args, _meta, _ctx) do
    nil
  end

  defp issue_for_call(_fun_name, [_, logger_metadata] = _args, meta, ctx) do
    issue_for_call(logger_metadata, meta, ctx)
  end

  defp issue_for_call(_fun_name, _args, _meta, _ctx) do
    nil
  end

  defp issue_for_call(logger_metadata, meta, ctx) do
    if Keyword.keyword?(logger_metadata) do
      case Keyword.drop(logger_metadata, ctx.params.metadata_keys) do
        [] ->
          nil

        missed ->
          issue_for(ctx, meta, Keyword.keys(missed))
      end
    end
  end

  defp find_metadata_keys(metadata_keys) do
    if metadata_keys == [] do
      find_metadata_keys_in_logger_config(:default_formatter) ||
        find_metadata_keys_in_logger_config(:console) || []
    else
      metadata_keys
    end
  end

  defp find_metadata_keys_in_logger_config(key) do
    :logger
    |> Application.get_env(key, [])
    |> Keyword.get(:metadata)
  end

  defp issue_for(ctx, meta, [trigger | _] = missed_keys) do
    format_issue(ctx,
      message: "Logger metadata key #{Enum.join(missed_keys, ", ")} not found in Logger config.",
      trigger: trigger,
      line_no: meta[:line]
    )
  end
end
