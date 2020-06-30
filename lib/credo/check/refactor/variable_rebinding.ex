defmodule Credo.Check.Refactor.VariableRebinding do
  use Credo.Check,
    tags: [:controversial],
    param_defaults: [allow_bang: false],
    explanations: [
      check: """
      You might want to refrain from rebinding variables.

      Although technically fine, rebinding to the same name can lead to less
      precise naming.

      Consider this example:

          def find_a_good_time do
            time = MyApp.DateTime.now
            time = MyApp.DateTime.later(time, 5, :days)
            {:ok, time} = verify_available_time(time)

            time
          end

      While there is nothing wrong with this, many would consider the following
      implementation to be easier to comprehend:

          def find_a_good_time do
            today = DateTime.now
            proposed_time = DateTime.later(today, 5, :days)
            {:ok, verified_time} = verify_available_time(proposed_time)

            verified_time
          end

      In some rare cases you might really want to rebind a variable.  This can be
      enabled "opt-in" on a per-variable basis by setting the :allow_bang option
      to true and adding a bang suffix sigil to your variable.

          def uses_mutating_parameters(params!) do
            params! = do_a_thing(params!)
            params! = do_another_thing(params!)
            params! = do_yet_another_thing(params!)
          end
      """,
      params: [
        allow_bang: "Variables with a bang suffix will be ignored."
      ]
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse([do: {:__block__, _, ast}], issues, {_, _, opt} = issue_meta) do
    variables =
      ast
      |> Enum.map(&find_assignments/1)
      |> List.flatten()
      |> Enum.filter(&(&1 != nil))
      |> Enum.filter(&only_variables/1)
      |> Enum.reject(&bang_sigil(&1, opt[:allow_bang]))

    duplicates =
      variables
      |> Enum.filter(fn {key, _} ->
        Enum.count(variables, fn {other, _} -> key == other end) >= 2
      end)
      |> Enum.reverse()
      |> Enum.uniq_by(&get_variable_name/1)

    new_issues =
      Enum.map(duplicates, fn {variable_name, line} ->
        issue_for(issue_meta, Atom.to_string(variable_name), line)
      end)

    if length(new_issues) > 0 do
      {ast, issues ++ new_issues}
    else
      {ast, issues}
    end
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp find_assignments({:=, _, [lhs, _rhs]}) do
    find_variables(lhs)
  end

  defp find_assignments(_), do: nil

  defp find_variables({:=, _, args}) do
    Enum.map(args, &find_variables/1)
  end

  # ignore pinned variables
  defp find_variables({:"::", _, [{:^, _, _} | _]}) do
    []
  end

  defp find_variables({:"::", _, [lhs | _rhs]}) do
    find_variables(lhs)
  end

  # ignore pinned variables
  defp find_variables({:^, _, _}) do
    []
  end

  defp find_variables({variable_name, meta, nil}) when is_list(meta) do
    {variable_name, meta[:line]}
  end

  defp find_variables(tuple) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list()
    |> find_variables
  end

  defp find_variables(list) when is_list(list) do
    list
    |> Enum.map(&find_variables/1)
    |> List.flatten()
    |> Enum.uniq_by(&get_variable_name/1)
  end

  defp find_variables(map) when is_map(map) do
    map
    |> Enum.into([])
    |> Enum.map(fn {_, value} -> value end)
    |> Enum.map(&find_variables/1)
    |> List.flatten()
    |> Enum.uniq_by(&get_variable_name/1)
  end

  defp find_variables(_), do: nil

  defp issue_for(issue_meta, trigger, line) do
    format_issue(
      issue_meta,
      message: "Variable \"#{trigger}\" was declared more than once.",
      trigger: trigger,
      line_no: line
    )
  end

  defp get_variable_name({name, _line}), do: name
  defp get_variable_name(nil), do: nil

  defp only_variables({name, _}) do
    name
    |> Atom.to_string()
    |> String.starts_with?("_")
    |> Kernel.not()
  end

  defp bang_sigil({name, _}, allowed) do
    allowed &&
      name
      |> Atom.to_string()
      |> String.ends_with?("!")
  end
end
