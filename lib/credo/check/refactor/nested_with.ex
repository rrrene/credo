defmodule Credo.Check.Refactor.NestedWith do
  use Credo.Check,
    id: "EX4035",
    base_priority: :high,
    explanations: [
      check: ~S"""
      A `with` should start at the top of a function body. One buried inside another
      block - an `if`, a `case`, or another `with` - splits a chain of pattern matches
      across two levels of control flow, which hides its failure paths and makes the
      `else` of either block ambiguous to a reader.

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

      An anonymous function is a scope rather than a block, so a `with` at the top of a
      `fn` body is not reported, however deeply that `fn` is nested. A comprehension is
      treated as a block, since `for` is control flow in the surrounding function. A
      `defmodule` is a scope too, so wrapping a module in `if Code.ensure_loaded?(Dep)`
      - conditional compilation, not control flow - does not report the bodies inside it.

      A `try` is neither, and is passed through: wrapping a chain in `try/rescue` does not
      branch it, and a `try` has no `else` to confuse with the one belonging to the `with`.

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
      """
    ]

  # A `with` at the top of one of these bodies is where it belongs. `defmodule` is a
  # scope because a module is routinely wrapped in a compile-time `if
  # Code.ensure_loaded?(Dep)`; that `if` is conditional compilation, not control flow
  # around the `with`, so it must not leak into the bodies the module defines.
  @scope_ops [:def, :defp, :defmacro, :defmacrop, :defmodule, :fn]

  # Anything that opens a body inside the current scope. `with` is handled separately,
  # since `{:with, _, args}` also matches a plain call of that name. `try` is absent on
  # purpose: it is transparent here, neither a scope nor a block. Wrapping a chain in
  # `try/rescue` does not branch it, and `try` has no `else` to confuse with the one
  # belonging to the `with`.
  @block_ops [:if, :unless, :case, :cond, :for, :receive]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)

    source_file
    |> SourceFile.ast()
    |> nested_lines(false, [])
    |> Enum.sort()
    |> Enum.uniq()
    |> Enum.map(&issue_for(ctx, &1))
  end

  # Walks the whole AST carrying one flag: whether a block has been entered since the
  # nearest enclosing scope. Written as an explicit recursion rather than
  # `Credo.Code.prewalk/3` because that flag has to be reset per branch, and reset
  # entirely on the way into a `fn`.
  defp nested_lines(ast, nested?, acc)

  defp nested_lines({op, _meta, args}, _nested?, acc) when op in @scope_ops and is_list(args) do
    Enum.reduce(args, acc, &nested_lines(&1, false, &2))
  end

  defp nested_lines({op, meta, args} = ast, nested?, acc) when is_atom(op) and is_list(args) do
    block? = opens_block?(op, args)
    acc = if nested? and op == :with and block?, do: [meta[:line] | acc], else: acc

    descend(ast, nested? or block?, acc)
  end

  defp nested_lines({_form, _meta, _args} = ast, nested?, acc), do: descend(ast, nested?, acc)

  defp nested_lines({left, right}, nested?, acc) do
    nested_lines(right, nested?, nested_lines(left, nested?, acc))
  end

  defp nested_lines(list, nested?, acc) when is_list(list) do
    Enum.reduce(list, acc, &nested_lines(&1, nested?, &2))
  end

  defp nested_lines(_ast, _nested?, acc), do: acc

  defp descend({form, _meta, args}, nested?, acc) do
    acc = nested_lines(form, nested?, acc)

    if is_list(args), do: nested_lines(args, nested?, acc), else: acc
  end

  # `with` is a special form, but `{:with, _, args}` alone also matches a call to a
  # function of that name. The special form always ends in a keyword list holding
  # `:do` (and `:else`, when present), so require that shape.
  defp opens_block?(:with, [_, _ | _] = args) do
    last = List.last(args)

    Keyword.keyword?(last) and Keyword.has_key?(last, :do)
  end

  defp opens_block?(:with, _args), do: false
  defp opens_block?(op, _args) when op in @block_ops, do: true
  defp opens_block?(_op, _args), do: false

  defp issue_for(ctx, line_no) do
    format_issue(
      ctx,
      message: "Nested `with` - flatten it into the enclosing chain, or extract it into a named function.",
      trigger: "with",
      line_no: line_no
    )
  end
end
