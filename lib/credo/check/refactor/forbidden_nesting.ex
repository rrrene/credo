defmodule Credo.Check.Refactor.ForbiddenNesting do
  use Credo.Check,
    id: "EX4035",
    base_priority: :high,
    param_defaults: [
      disallow_nested_in: [with: [:if, :unless, :case, :cond, :for, :receive, :with]],
      allow_one_liners: false
    ],
    explanations: [
      check: ~S"""
      Some control flow constructs read badly when one is buried inside another.
      Which pairs are a problem is largely a matter of team style, so the pairs
      reported here are configured rather than fixed.

      Out of the box one pair is forbidden: a `with` nested in any other block. A
      `with` should start at the top of a function body. One buried inside an `if`, a
      `case`, or another `with` splits a chain of pattern matches across two levels of
      control flow, which hides its failure paths and makes the `else` of either block
      ambiguous to a reader.

      Nested in another `with`:

          with {:ok, conn} <- connect(host) do
            request = build_request(conn)

            with {:ok, response} <- send(conn, request) do
              {:ok, response}
            end
          end

      A non-`<-` clause in the middle of a chain is legal, so this flattens:

          with {:ok, conn} <- connect(host),
               request = build_request(conn),
               {:ok, response} <- send(conn, request) do
            {:ok, response}
          end

      Nested in an `if`:

          def fetch(host, deadline) do
            if expired?(deadline) do
              {:error, :timeout}
            else
              with {:ok, conn} <- connect(host) do
                read(conn)
              end
            end
          end

      Here the fix is to give the branch a name, so the `with` opens a body of its own:

          def fetch(host, deadline) do
            if expired?(deadline), do: {:error, :timeout}, else: fetch(host)
          end

          defp fetch(host) do
            with {:ok, conn} <- connect(host) do
              read(conn)
            end
          end

      ## Forbidding other pairs

      A rule is written "inner construct, nested in any of these outer constructs", and
      the value given replaces the default rather than adding to it:

          {Credo.Check.Refactor.ForbiddenNesting,
           disallow_nested_in: [
             with: [:if, :unless, :case, :cond, :for, :receive, :with],
             if: [:case, :if],
             case: :any
           ]}

      With `if: [:case]` configured, this reports:

          def price(order, customer) do
            case customer.tier do
              :retail ->
                if order.total > 100 do    # <-- an `if` nested in a `case`
                  order.total * 0.95
                else
                  order.total
                end

              :wholesale ->
                order.total * 0.8
            end
          end

      The fix is usually to let one construct do the branching. Here the `case` can
      take over, since its clauses accept guards:

          def price(%{total: total}, %{tier: :retail}) when total > 100, do: total * 0.95
          def price(%{total: total}, %{tier: :retail}), do: total
          def price(%{total: total}, %{tier: :wholesale}), do: total * 0.8

      ## What counts as nesting

      Nesting is measured from the nearest enclosing *scope*, not from the top of the
      file. `def`, `defp`, `defmacro`, `defmacrop`, `fn` and `defmodule` all start a
      fresh count, so a construct at the top of a function body is never reported,
      and neither is one at the top of an `fn` body, however deeply that `fn` is
      nested. `defmodule` is a scope because a module is routinely wrapped in a
      compile-time `if Code.ensure_loaded?(Dep)`; that `if` is conditional
      compilation, not control flow around the code the module defines.

      Nesting is also transitive: with only `with: [:if]` configured, a `with` inside
      a `case` inside an `if` is still reported, because the `if` still encloses it.
      Each construct is reported once, naming the innermost enclosing block that a
      rule matched.

      A `try` is neither a scope nor a block, and is passed through: wrapping code in
      `try/rescue` does not branch it, and a `try` has no `else` to confuse with the
      one belonging to a `with`. So a `with` at the top of a function body stays
      unreported when you wrap it in a `try`, and a `with` inside an `if` stays
      reported when you do.

          def execute(query) do
            try do
              with {:ok, query} <- validate(query),
                   {:ok, result} <- run(query) do
                {:ok, result}
              end
            rescue
              StaleReferenceError -> {:error, :stale_reference}
            end
          end
      """,
      params: [
        disallow_nested_in: """
        The nesting combinations to report, as `inner_construct: outer_constructs`.

        Both sides accept `:if`, `:unless`, `:case`, `:cond`, `:for`, `:receive` and
        `:with`. The outer side also accepts `:any` to forbid the inner construct
        inside every one of them.

        Setting this replaces the default, it does not extend it. Pass `[]` to disable
        the check without removing it from your configuration.

        Example:

            disallow_nested_in: [
              with: [:if, :unless, :case, :cond, :for, :receive, :with],
              if: :any
            ]
        """,
        allow_one_liners: """
        Do not report a nested construct written in keyword form
        (e.g. `if x, do: y, else: z`).

        This applies to the nested construct being reported, not to the one it is
        nested in: a one-liner still counts as an enclosing block for anything
        inside it.
        """
      ]
    ]

  alias Credo.IssueMeta

  # A block at the top of one of these bodies is where it belongs.
  @scope_ops [:def, :defp, :defmacro, :defmacrop, :defmodule, :fn]

  # Everything that opens a body inside the current scope, and therefore everything
  # that may appear on either side of a rule. `try` is absent on purpose: it is
  # transparent here, neither a scope nor a block.
  @block_ops [:if, :unless, :case, :cond, :for, :receive, :with]

  @advice %{
    with: "flatten it into the enclosing chain, or extract it into a named function",
    if: "extract it into a named function, or let a single `cond` do the branching",
    unless: "extract it into a named function, or let a single `cond` do the branching",
    case: "extract it into a named function, or move the branching into its clauses",
    cond: "extract it into a named function, or merge the conditions into one `cond`",
    for: "extract it into a named function, or add the outer condition as a filter",
    receive: "extract it into a named function"
  }

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)

    case normalize_rules(ctx.params.disallow_nested_in) do
      empty when empty == %{} ->
        []

      rules ->
        issue_meta = IssueMeta.for(source_file, params)
        config = %{rules: rules, allow_one_liners?: ctx.params.allow_one_liners == true}

        source_file
        |> SourceFile.ast()
        |> nested(config, [], [])
        |> Enum.sort()
        |> Enum.map(&issue_for(issue_meta, &1))
    end
  end

  #
  # Traversal
  #

  # Walks the whole AST carrying the list of blocks entered since the nearest
  # enclosing scope, innermost first. Written as an explicit recursion rather than
  # `Credo.Code.prewalk/3` because that list has to be reset per branch, and reset
  # entirely on the way into a scope.
  defp nested(ast, config, enclosing, acc)

  defp nested({op, _meta, args}, config, _enclosing, acc)
       when op in @scope_ops and is_list(args) do
    Enum.reduce(args, acc, &nested(&1, config, [], &2))
  end

  defp nested({op, meta, args} = ast, config, enclosing, acc)
       when is_atom(op) and is_list(args) do
    if opens_block?(op, args) do
      # `enclosing` is innermost-first, so this names the tightest containment and
      # yields at most one issue per construct.
      acc =
        case Enum.find(enclosing, &disallowed?(config.rules, op, &1)) do
          nil -> acc
          outer_op -> put_line(acc, config, meta, op, outer_op)
        end

      descend(ast, config, [op | enclosing], acc)
    else
      descend(ast, config, enclosing, acc)
    end
  end

  defp nested({_form, _meta, _args} = ast, config, enclosing, acc) do
    descend(ast, config, enclosing, acc)
  end

  defp nested({left, right}, config, enclosing, acc) do
    nested(right, config, enclosing, nested(left, config, enclosing, acc))
  end

  defp nested(list, config, enclosing, acc) when is_list(list) do
    Enum.reduce(list, acc, &nested(&1, config, enclosing, &2))
  end

  defp nested(_ast, _config, _enclosing, acc), do: acc

  defp descend({form, _meta, args}, config, enclosing, acc) do
    acc = nested(form, config, enclosing, acc)

    if is_list(args), do: nested(args, config, enclosing, acc), else: acc
  end

  defp put_line(acc, config, meta, op, outer_op) do
    if config.allow_one_liners? and one_liner?(meta) do
      acc
    else
      [{meta[:line], op, outer_op} | acc]
    end
  end

  # A `do ... end` block carries `:end` in its token metadata, the keyword form
  # does not.
  defp one_liner?(meta), do: not Keyword.has_key?(meta, :end)

  # `with` is a special form, but `{:with, _, args}` alone also matches a call to a
  # function of that name - and the same is true of any other op here. A block form
  # always ends in a keyword list holding `:do`, so require that shape.
  defp opens_block?(op, args) when op in @block_ops do
    last = List.last(args)

    Keyword.keyword?(last) and Keyword.has_key?(last, :do)
  end

  defp opens_block?(_op, _args), do: false

  defp disallowed?(rules, inner_op, outer_op) do
    case rules do
      %{^inner_op => :any} -> true
      %{^inner_op => outer_ops} -> MapSet.member?(outer_ops, outer_op)
      _ -> false
    end
  end

  #
  # Params
  #

  # The framework validates param names but never their values, so a typo here
  # would otherwise silently disable a rule.
  defp normalize_rules(rules) when is_list(rules) or is_map(rules) do
    Map.new(rules, fn
      {inner_op, outer_ops} ->
        {validate_op!(inner_op), normalize_outer_ops(outer_ops)}

      other ->
        raise ArgumentError,
              "#{inspect(__MODULE__)}: expected `inner_construct: outer_constructs`, got: #{inspect(other)}"
    end)
  end

  defp normalize_rules(rules) do
    raise ArgumentError,
          "#{inspect(__MODULE__)}: `:disallow_nested_in` must be a keyword list or a map, got: #{inspect(rules)}"
  end

  defp normalize_outer_ops(:any), do: :any

  defp normalize_outer_ops(outer_ops) when is_list(outer_ops) do
    outer_ops |> Enum.map(&validate_op!/1) |> MapSet.new()
  end

  defp normalize_outer_ops(outer_op) when is_atom(outer_op) do
    MapSet.new([validate_op!(outer_op)])
  end

  defp normalize_outer_ops(outer_ops) do
    raise ArgumentError,
          "#{inspect(__MODULE__)}: expected a list of constructs or `:any`, got: #{inspect(outer_ops)}"
  end

  defp validate_op!(op) when op in @block_ops, do: op

  defp validate_op!(:try) do
    raise ArgumentError,
          "#{inspect(__MODULE__)}: `:try` is transparent to this check - wrapping code in " <>
            "`try` does not branch it - and cannot be used in `:disallow_nested_in`."
  end

  defp validate_op!(op) when op in @scope_ops do
    raise ArgumentError,
          "#{inspect(__MODULE__)}: `#{inspect(op)}` opens a new scope rather than a nested " <>
            "block, and cannot be used in `:disallow_nested_in`."
  end

  defp validate_op!(op) do
    raise ArgumentError,
          "#{inspect(__MODULE__)}: `#{inspect(op)}` does not open a block. " <>
            "Expected one of #{inspect(@block_ops)}."
  end

  #
  # Issues
  #

  defp issue_for(issue_meta, {line_no, inner_op, outer_op}) do
    format_issue(
      issue_meta,
      message: "Nested `#{inner_op}` inside `#{outer_op}` - #{Map.fetch!(@advice, inner_op)}.",
      trigger: to_string(inner_op),
      line_no: line_no
    )
  end
end
