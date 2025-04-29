defmodule Credo.Check.Warning.PipeToLogger do
  @moduledoc false

  use Credo.Check,
    id: "EX??",
    base_priority: :normal,
    category: :warning,
    explanations: [
      check: """
      Calls into Logger can be purged when `:compile_time_purge_matching` is enabled in
      the Logger configuration. This will remove the entire pipeline.
      Use |> tap(&Logger.info(&1)) instead.
      """
    ]

  @logger_functions [
    :debug,
    :info,
    :notice,
    :warn,
    :warning,
    :error,
    :critical,
    :alert,
    :emergency
  ]

  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse(
         {:|>, meta, [_, {{:., _, [{:__aliases__, _, [:Logger]}, function]}, _, _}]} = ast,
         issues,
         issue_meta
       )
       when function in @logger_functions do
    trigger = "|> Logger.#{function}"

    new_issue =
      format_issue(
        issue_meta,
        message: "There should be no `@#{trigger} calls.",
        trigger: "#{trigger}",
        line_no: meta[:line],
        column: meta[:column]
      )

    {ast, issues ++ [new_issue]}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end
end
