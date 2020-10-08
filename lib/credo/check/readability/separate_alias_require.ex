defmodule Credo.Check.Readability.SeparateAliasRequire do
  use Credo.Check,
    base_priority: :low,
    explanations: [
      check: """
      All instances of `alias` should be consecutive within a file.
      Likewise, all instances of `require` should be consecutive within a file.

      For example:

          defmodule Foo do
            require Logger
            alias Foo.Bar

            alias Foo.Baz
            require Integer

            # ...
          end

      should be changed to:

          defmodule Foo do
            require Integer
            require Logger

            alias Foo.Bar
            alias Foo.Baz

            # ...
          end

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """
    ]

  alias Credo.Code.Block

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse({:defmodule, _, _} = ast, issues, issue_meta) do
    {_previous_calls, issues} =
      ast
      |> Block.calls_in_do_block()
      |> Enum.reduce({[], issues}, fn
        {macro_name, meta, args}, {previous_calls, issues}
        when is_atom(macro_name) and is_list(args) ->
          cond do
            List.last(previous_calls) == macro_name ->
              {previous_calls, issues}

            macro_name in [:alias, :require] and Enum.member?(previous_calls, macro_name) ->
              {previous_calls, issues ++ [issue_for(issue_meta, meta[:line], macro_name)]}

            true ->
              {previous_calls ++ [macro_name], issues}
          end

        _, memo ->
          memo
      end)

    {ast, issues}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issue_for(issue_meta, line_no, type) do
    format_issue(issue_meta, message: message(type), line_no: line_no)
  end

  def message(:alias), do: "aliases should be consecutive within a file"
  def message(:require), do: "requires should be consecutive within a file"
end
