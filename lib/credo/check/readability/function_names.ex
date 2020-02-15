defmodule Credo.Check.Readability.FunctionNames do
  use Credo.Check,
    base_priority: :high,
    explanations: [
      check: """
      Function, macro, and guard names are always written in snake_case in Elixir.

          # snake_case

          def handle_incoming_message(message) do
          end

          # not snake_case

          def handleIncomingMessage(message) do
          end

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """
    ]

  alias Credo.Code.Name

  @def_ops [:def, :defp, :defmacro, :defmacrop, :defguard, :defguardp]
  @all_sigil_chars ~w(a A b B c C d D e E f F g G h H i I j J k K l L m M n N o O p P q Q r R s S t T u U v V w W x X y Y z Z)
  @all_sigil_atoms Enum.map(@all_sigil_chars, &:"sigil_#{&1}")

  # all non-special-form operators
  @all_nonspecial_operators ~W(! && ++ -- .. <> =~ @ |> || != !== * + - / <= == === > >= ||| &&& <<< >>> <<~ ~>> <~ ~> <~> <|> ^^^ ~~~)a

  @doc false
  def run(%SourceFile{} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    source_file
    |> Credo.Code.prewalk(&traverse(&1, &2, issue_meta), empty_issues())
    |> issues_list()
  end

  defp empty_issues(), do: %{}

  defp add_issue(issues, name, arity, issue), do: Map.put_new(issues, {name, arity}, issue)

  defp issues_list(issues) do
    issues
    |> Map.values()
    |> Enum.sort_by(& &1.line_no)
  end

  # Ignore sigil definitions
  for sigil <- @all_sigil_atoms do
    defp traverse(
           {op, _meta, [{unquote(sigil), _sigil_meta, _args} | _tail]} = ast,
           issues,
           _issue_meta
         )
         when op in [:def, :defmacro] do
      {ast, issues}
    end
  end

  for op <- @def_ops do
    # Ignore variables named e.g. `defp`
    defp traverse({unquote(op), _meta, nil} = ast, issues, _issue_meta) do
      {ast, issues}
    end

    # ignore non-special-form (overridable) operators
    defp traverse(
           {unquote(op), _meta, [{operator, _at_meta, _args} | _tail]} = ast,
           issues,
           _issue_meta
         )
         when operator in @all_nonspecial_operators do
      {ast, issues}
    end

    defp traverse({unquote(op), _meta, arguments} = ast, issues, issue_meta) do
      {ast, issues_for_definition(arguments, issues, issue_meta)}
    end
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issues_for_definition(body, issues, issue_meta) do
    case Enum.at(body, 0) do
      {:when, _when_meta, [{name, meta, args} | _guard]} ->
        issues_for_name(name, args, meta, issues, issue_meta)

      {name, meta, args} when is_atom(name) ->
        issues_for_name(name, args, meta, issues, issue_meta)

      _ ->
        issues
    end
  end

  defp issues_for_name({:unquote, _, _}, _args, _meta, issues, _issue_meta) do
    issues
  end

  defp issues_for_name(name, args, meta, issues, issue_meta) do
    if name |> to_string |> Name.snake_case?() do
      issues
    else
      issue = issue_for(issue_meta, meta[:line], name)
      arity = length(args || [])

      add_issue(issues, name, arity, issue)
    end
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message: "Function/macro/guard names should be written in snake_case.",
      trigger: trigger,
      line_no: line_no
    )
  end
end
