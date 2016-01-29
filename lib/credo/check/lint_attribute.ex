defmodule Credo.Check.LintAttribute do
  defstruct line: nil,
            meta: nil,      # TODO: remove these
            arguments: nil, # TODO: as they are for debug purposes only
            scope: nil,
            value: nil

  def ignores_issue?(%__MODULE__{value: false} = lint_attribute, issue) do
    lint_attribute |> IO.inspect
    issue.line_no |> IO.inspect
    issue.scope |> IO.inspect
    (lint_attribute.scope == issue.scope) |> IO.inspect
  end
  def ignores_issue?(lint_attribute, issue) do
    false
  end

  def value_for([false]), do: false
  def value_for([list]) when is_list(list) do
    list |> Enum.map(&value_for/1)
  end
  def value_for({{:__aliases__, _, mod_list}, params}) do
    {Module.concat(mod_list), params}
  end
  def value_for(_), do: nil

end
