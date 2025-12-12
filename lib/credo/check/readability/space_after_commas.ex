defmodule Credo.Check.Readability.SpaceAfterCommas do
  use Credo.Check,
    id: "EX3024",
    tags: [:formatter],
    explanations: [
      check: """
      You can use white-space after commas to make items of lists,
      tuples and other enumerations easier to separate from one another.

          # preferred

          alias Project.{Alpha, Beta}

          def some_func(first, second, third) do
            list = [1, 2, 3, 4, 5]
            # ...
          end

          # NOT preferred - items are harder to separate

          alias Project.{Alpha,Beta}

          def some_func(first,second,third) do
            list = [1,2,3,4,5]
            # ...
          end

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """
    ]

  import CredoTokenizer.Guards

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    source_file
    |> Credo.Code.Token.reduce(&collect(&1, &2, &3, &4))
    |> Enum.map(&issue_for(issue_meta, &1))
  end

  defp collect(_prev, {{:",", _}, {line, col, _, _}, _, _} = left, {kind, {_, _, _, _}, value, _} = right, acc)
       when no_space_between(left, right) and not is_eol(right) do
    acc ++ [{line, col, trigger(kind, value)}]
  end

  defp collect(_prev, _current, _next, acc), do: acc

  defp trigger({:string, :binary}, _), do: ",\""
  defp trigger({:string, :list}, _), do: ",'"
  defp trigger({:char, nil}, _), do: ",?"
  defp trigger({:atom, nil}, _), do: ",:"
  defp trigger({:%{}, nil}, _), do: ",%"

  defp trigger(_, value), do: ",#{String.first(to_string(value))}"

  defp issue_for(issue_meta, {line_no, column, trigger}) do
    format_issue(issue_meta, message: "Space missing after comma.", trigger: trigger, line_no: line_no, column: column)
  end
end
