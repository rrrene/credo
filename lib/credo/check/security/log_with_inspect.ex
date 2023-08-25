defmodule Credo.Check.Security.LogWithInspect do
  @moduledoc """
  Log with inspect allows to flag logging statement that uses inspect. This
  can lead to PII or credential leaking frequently
  """

  use Credo.Check,
    base_priority: :normal,
    category: :security,
    explanations: [
      check: """
      Logging should only be used to output valuable and safe data. When using inspect on a var,
      especialy map or keywords, you can run the risk to expose sensitive data accidentally.

      So while this is fine for a string type of var:

      var = "some safe value"
      Logger.info("logging stuff \#{var}")

      The code in this example ...

      var = %{email: "verysensitive@pexample.com",
              other_key: "the thing I was only expected to see"}

      Logger.info("logging stuff \#{inspect(var)}")

      ... should be refactored to look like this:

      Logger.info("logging stuff \#{var%{:other_key}}")

      """
    ]

  @logger_functions [:debug, :info, :warn, :error]

  @spec run(Macro.t(), keyword()) :: no_return()
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    dbg(:HER)
    # we'll walk the `source_file`'s AST and look for module attributes matching `@rejected_names`
    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  # found a Logger function
  defp traverse(
         {{:., _meta1, [{:__aliases__, _meta2, [:Logger]}, fun_name]}, meta, arguments} = ast,
         state,
         issue_meta
       )
       when fun_name in @logger_functions do
    issue = find_issue(arguments, meta, issue_meta)

    {ast, add_issue_to_state(state, issue)}
  end

  # For all AST nodes not matching the pattern above, we simply do nothing:
  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp add_issue_to_state(state, nil), do: state

  defp add_issue_to_state(issues, issue) do
    [issue | issues]
  end

  defp find_issue(arguments, _meta, _issue_meta) when is_binary(arguments) do
    nil
  end

  defp find_issue(arguments, _meta, issue_meta) do
    {_new_ast, acc} =
      Macro.prewalk(arguments, [], fn
        {:inspect, meta, children}, acc ->
          {{:inspect, meta, children}, [meta | acc]}

        other, acc ->
          {other, acc}
      end)

    if meta = List.first(acc) do
      issue_for(":inspect", meta[:line], issue_meta)
    end
  end

  defp issue_for(trigger, line_no, issue_meta) do
    format_issue(
      issue_meta,
      message:
        "You should not inspect in your logs. This could expose sensitive data in logs and therefore external 3rd parties.",
      trigger: "@#{trigger}",
      line_no: line_no
    )
  end
end
