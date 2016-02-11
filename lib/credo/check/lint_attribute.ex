defmodule Credo.Check.LintAttribute do
  defstruct line: nil,
            meta: nil,      # TODO: remove these
            arguments: nil, # TODO: as they are for debug purposes only
            scope: nil,
            value: nil

  def from_ast({:@, meta, [{:lint, _, arguments}]}) do
    %__MODULE__{
      meta: meta,
      arguments: arguments,
      value: value_for(arguments)
    }
  end

  def ignores_issue?(%__MODULE__{value: false} = lint_attribute, issue) do
    lint_attribute.scope == issue.scope
  end
  def ignores_issue?(%__MODULE__{value: check_list} = lint_attribute, issue) when is_list(check_list) do
    if lint_attribute.scope == issue.scope do
      check_list
      |> Enum.any?(&check_tuple_ignores_issue?(&1, issue))
    else
      false
    end
  end
  def ignores_issue?(_lint_attribute, _issue) do
    false
  end

  defp check_tuple_ignores_issue?({check_or_regex, false}, issue) do
    if check_or_regex |> Regex.regex? do
      issue.check |> to_string |> String.match?(check_or_regex)
    else
      issue.check == check_or_regex
    end
  end
  defp check_tuple_ignores_issue?(_, _issue) do
    false
  end

  def value_for([false]), do: false
  def value_for([list]) when is_list(list) do
    list |> Enum.map(&value_for/1)
  end
  def value_for([tuple]) when is_tuple(tuple) do
    [tuple |> value_for()]
  end
  def value_for({{:__aliases__, _, mod_list}, params}) do
    {Module.concat(mod_list), params}
  end
  def value_for({{:sigil_r, _, _} = sigil, params}) do
    {result, _binding} = Code.eval_quoted(sigil)
    {result, params}
  end
  def value_for({{:sigil_R, _, _} = sigil, params}) do
    {result, _binding} = Code.eval_quoted(sigil)
    {result, params}
  end
  def value_for(_) do
    nil
  end

end
