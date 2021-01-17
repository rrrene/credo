defmodule Credo.Check.Refactor.EnumHelpers do
  def traverse(
        {{:., _, [{:__aliases__, meta, [:Enum]}, second]}, _,
         [{{:., _, [{:__aliases__, _, [:Enum]}, first]}, _, _}, _]} = ast,
        issues,
        issue_meta,
        message,
        trigger,
        first,
        second,
        module
      ) do
    new_issue = issue_for(issue_meta, meta[:line], message, trigger, module)
    {ast, issues ++ List.wrap(new_issue)}
  end

  def traverse(
        {:|>, meta,
         [
           {{:., _, [{:__aliases__, _, [:Enum]}, first]}, _, _},
           {{:., _, [{:__aliases__, _, [:Enum]}, second]}, _, _}
         ]} = ast,
        issues,
        issue_meta,
        message,
        trigger,
        first,
        second,
        module
      ) do
    new_issue = issue_for(issue_meta, meta[:line], message, trigger, module)
    {ast, issues ++ List.wrap(new_issue)}
  end

  def traverse(
        {{:., meta, [{:__aliases__, _, [:Enum]}, second]}, _,
         [
           {:|>, _, [_, {{:., _, [{:__aliases__, _, [:Enum]}, first]}, _, _}]},
           _
         ]} = ast,
        issues,
        issue_meta,
        message,
        trigger,
        first,
        second,
        module
      ) do
    new_issue = issue_for(issue_meta, meta[:line], message, trigger, module)
    {ast, issues ++ List.wrap(new_issue)}
  end

  def traverse(
        {:|>, meta,
         [
           {:|>, _,
            [
              _,
              {{:., _, [{:__aliases__, _, [:Enum]}, first]}, _, _}
            ]},
           {{:., _, [{:__aliases__, _, [:Enum]}, second]}, _, _}
         ]} = ast,
        issues,
        issue_meta,
        message,
        trigger,
        first,
        second,
        module
      ) do
    new_issue = issue_for(issue_meta, meta[:line], message, trigger, module)
    {ast, issues ++ List.wrap(new_issue)}
  end

  def traverse(ast, issues, _issue_meta, _message, _trigger, _first, _second, _module) do
    {ast, issues}
  end

  defp issue_for(issue_meta, line_no, message, trigger, module) do
    module.format_issue(
      issue_meta,
      message: message,
      trigger: trigger,
      line_no: line_no
    )
  end
end
