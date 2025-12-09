defmodule Credo.Check.Refactor.MatchInCondition do
  use Credo.Check,
    id: "EX4016",
    param_defaults: [
      allow_tagged_tuples: false,
      allow_operators: false
    ],
    explanations: [
      check: """
      Pattern matching should only ever be used for simple assignments
      inside `if` and `unless` clauses.

      While this fine:

          # okay, simple wildcard assignment:

          if contents = File.read!("foo.txt") do
            do_something(contents)
          end

      the following should be avoided, since it mixes a pattern match with a
      condition and do/else blocks.

          # considered too "complex":

          if {:ok, contents} = File.read("foo.txt") do
            do_something(contents)
          end

          # also considered "complex":

          if allowed? && ( contents = File.read!("foo.txt") ) do
            do_something(contents)
          end

      If you want to match for something and execute another block otherwise,
      consider using a `case` statement:

          case File.read("foo.txt") do
            {:ok, contents} ->
              do_something()
            _ ->
              do_something_else()
          end

      """,
      params: [
        allow_tagged_tuples:
          "Allow tagged tuples in conditions, e.g. `if {:ok, contents} = File.read( \"foo.txt\") do`",
        allow_operators:
          "Allow operators in conditions, e.g. `if contents = File.read(input <> \".txt\") do`"
      ]
    ]

  # all non-special-form operators
  @all_nonspecial_operators ~W(! && ++ -- .. <> =~ |> || != !== * + - / ** < <= == === > >= ||| &&& <<< >>> <<~ ~>> <~ ~> <~> <|> ^^^ ~~~ +++ ---)a

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({op, _, nil} = ast, ctx) when op in [:if, :unless] do
    {ast, ctx}
  end

  defp walk({op, _, arguments} = ast, ctx) when op in [:if, :unless] do
    condition_head = Enum.reject(arguments, &Keyword.keyword?/1)

    ctx =
      Credo.Code.prewalk(
        condition_head,
        &find_match(&1, &2, op, condition_head),
        ctx
      )

    {ast, ctx}
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp find_match({:=, meta, [{var_name, _, nil}, rhs]} = ast, ctx, op, op_arguments)
       when is_atom(var_name) do
    assignment_in_body? = Enum.member?(op_arguments, ast)
    has_illegal_ops? = !ctx.params.allow_operators && contains_operators?(rhs)

    if assignment_in_body? or has_illegal_ops? do
      if has_illegal_ops? do
        {ast, put_issue(ctx, issue_for(op, meta, ctx))}
      else
        {ast, ctx}
      end
    else
      {ast, put_issue(ctx, issue_for(op, meta, ctx))}
    end
  end

  defp find_match({:=, meta, [{tag_atom, {var_name, _, nil}}, _rhs]} = ast, ctx, op, _op_args)
       when is_atom(var_name) and is_atom(tag_atom) do
    if ctx.params.allow_tagged_tuples do
      {ast, ctx}
    else
      {ast, put_issue(ctx, issue_for(op, meta, ctx))}
    end
  end

  defp find_match({:=, meta, _} = ast, ctx, op, _op_args) do
    {ast, put_issue(ctx, issue_for(op, meta, ctx))}
  end

  defp find_match(ast, ctx, _op, _op_args) do
    {ast, ctx}
  end

  defp contains_operators?(ast) do
    case ast do
      {op, _, _} when op in @all_nonspecial_operators -> true
      {_, _, args} when is_list(args) -> Enum.any?(args, &contains_operators?/1)
      _ -> false
    end
  end

  defp issue_for(op, meta, issue_meta) do
    format_issue(
      issue_meta,
      message: "Avoid matches in `#{op}` conditions.",
      trigger: "=",
      line_no: meta[:line]
    )
  end
end
