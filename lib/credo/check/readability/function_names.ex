defmodule Credo.Check.Readability.FunctionNames do
  use Credo.Check,
    id: "EX3004",
    base_priority: :high,
    param_defaults: [
      allow_acronyms: false
    ],
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
      """,
      params: [
        allow_acronyms: "Allows acronyms like HTTP or OTP in function names."
      ]
    ]

  alias Credo.Code.Name

  @def_ops [:def, :defp, :defmacro, :defmacrop, :defguard, :defguardp]
  @all_sigil_chars ~w(a A b B c C d D e E f F g G h H i I j J k K l L m M n N o O p P q Q r R s S t T u U v V w W x X y Y z Z)
  @all_sigil_atoms Enum.map(@all_sigil_chars, &:"sigil_#{&1}")

  # all non-special-form operators
  @all_nonspecial_operators ~W(! && ++ -- .. <> =~ @ |> || != !== * + - / ** < <= == === > >= ||| &&& <<< >>> <<~ ~>> <~ ~> <~> <|> ^^^ ~~~ +++ ---)a

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params \\ []) do
    ctx = Context.build(source_file, params, __MODULE__, %{issues: %{}})
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)

    Map.values(result.issues)
  end

  # Ignore sigil definitions
  for sigil <- @all_sigil_atoms do
    defp walk({op, _meta, [{unquote(sigil), _sigil_meta, _args} | _tail]} = ast, ctx)
         when op in [:def, :defp, :defmacro, :defmacrop] do
      {ast, ctx}
    end

    defp walk(
           {op, _op_meta,
            [{:when, _when_meta, [{unquote(sigil), _sigil_meta, _args} | _tail]}, _block]} = ast,
           ctx
         )
         when op in [:def, :defp, :defmacro, :defmacrop] do
      {ast, ctx}
    end
  end

  # NOTE: see above for how we want to avoid `sigil_X` definitions
  for op <- @def_ops do
    # Ignore variables named e.g. `defp`
    defp walk({unquote(op), _meta, nil} = ast, ctx) do
      {ast, ctx}
    end

    # ignore non-special-form (overridable) operators
    defp walk({unquote(op), _meta, [{operator, _at_meta, _args} | _tail]} = ast, ctx)
         when operator in @all_nonspecial_operators do
      {ast, ctx}
    end

    # ignore non-special-form (overridable) operators
    defp walk(
           {unquote(op), _meta,
            [
              {:when, _,
               [
                 {operator, _, _} | _
               ]}
              | _
            ]} = ast,
           ctx
         )
         when operator in @all_nonspecial_operators do
      {ast, ctx}
    end

    defp walk(
           {unquote(op), _meta, [{:when, _when_meta, [{name, meta, args} | _guard]} | _]} = ast,
           ctx
         ) do
      {ast, process_call(name, args, meta, ctx)}
    end

    defp walk({unquote(op), _meta, [{name, meta, args} | _]} = ast, ctx) when is_atom(name) do
      {ast, process_call(name, args, meta, ctx)}
    end

    defp walk({unquote(op), _meta, _} = ast, ctx) do
      {ast, ctx}
    end
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp process_call({:unquote, _, _}, _args, _meta, ctx) do
    ctx
  end

  defp process_call(
         "sigil_" <> sigil_letters = name,
         args,
         meta,
         ctx
       ) do
    cond do
      # multi-letter sigil
      String.match?(sigil_letters, ~r/^[A-Z]+$/) ->
        ctx

      Name.snake_case?(name, ctx.params.allow_acronyms) ->
        ctx

      true ->
        issue = issue_for(ctx, meta[:line], name)

        add_issue_with_signature(ctx, name, args, issue)
    end
  end

  defp process_call("" <> name, args, meta, ctx) do
    if Name.snake_case?(name, ctx.params.allow_acronyms) do
      ctx
    else
      add_issue_with_signature(ctx, name, args, issue_for(ctx, meta[:line], name))
    end
  end

  defp process_call(name, args, meta, ctx) do
    name |> to_string |> process_call(args, meta, ctx)
  end

  defp issue_for(ctx, line_no, trigger) do
    format_issue(
      ctx,
      message: "Function/macro/guard names should be written in snake_case.",
      trigger: trigger,
      line_no: line_no
    )
  end

  def add_issue_with_signature(ctx, name, args, issue) do
    key = "#{name}/#{Enum.count(List.wrap(args))}"

    %{ctx | issues: Map.put(ctx.issues, key, issue)}
  end
end
