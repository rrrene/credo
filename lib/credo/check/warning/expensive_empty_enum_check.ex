defmodule Credo.Check.Warning.ExpensiveEmptyEnumCheck do
  use Credo.Check,
    base_priority: :high,
    explanations: [
      # TODO: improve checkdoc
      check: """
      Checking if the size of the enum is `0` can be very expensive, since you are
      determining the exact count of elements.

      Checking if an enum is empty should be done by using

          Enum.empty?(enum)

      or

          list == []


      For Enum.count/2: Checking if an enum doesn't contain specific elements should
      be done by using

          not Enum.any?(enum, condition)

      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  @enum_count_pattern quote do: {
                              {:., _, [{:__aliases__, _, [:Enum]}, :count]},
                              _,
                              _
                            }
  @length_pattern quote do: {:length, _, [_]}
  @comparisons [
    {@enum_count_pattern, 0},
    {0, @enum_count_pattern},
    {@length_pattern, 0},
    {0, @length_pattern}
  ]
  @operators [:==, :===]

  for {lhs, rhs} <- @comparisons,
      operator <- @operators do
    defp traverse(
           {unquote(operator), meta, [unquote(lhs), unquote(rhs)]} = ast,
           issues,
           issue_meta
         ) do
      {ast, issues_for_call(meta, issues, issue_meta, ast)}
    end
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issues_for_call(meta, issues, issue_meta, ast) do
    [issue_for(issue_meta, meta[:line], Macro.to_string(ast), suggest(ast)) | issues]
  end

  defp suggest({_op, _, [0, {_pattern, _, args}]}), do: suggest_for_arity(Enum.count(args))
  defp suggest({_op, _, [{_pattern, _, args}, 0]}), do: suggest_for_arity(Enum.count(args))

  defp suggest_for_arity(2), do: "`not Enum.any?/2`"
  defp suggest_for_arity(1), do: "Enum.empty?/1 or list == []"

  defp issue_for(issue_meta, line_no, trigger, suggestion) do
    format_issue(
      issue_meta,
      message: "#{trigger} is expensive. Prefer #{suggestion}",
      trigger: trigger,
      line_no: line_no
    )
  end
end
