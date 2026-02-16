defmodule Credo.Check.Readability.StrictModuleDirectiveScope do
  use Credo.Check,
    id: "EX5027",
    base_priority: :low,
    category: :readability,
    tags: [:controversial],
    param_defaults: [
      directives: [:alias, :require, :import, :use],
      allow_in_private_functions: false,
      allow_in_test_macros: true,
      allow_in_quote_blocks: true,
      exclude_functions: []
    ],
    explanations: [
      check: """
      Module directives should be defined at the module level, not inside functions.

      Module directives (`alias`, `require`, `import`, `use`) that appear inside
      function bodies can make code harder to follow and obscure module dependencies.
      By requiring all directives to be declared at the module level, readers can
      quickly understand a module's dependencies by looking at the top of the file.

      ## Preferred Style

          defmodule MyModule do
            alias MyApp.DataProcessor
            alias MyApp.Validator
            require Logger

            def process_data(data) do
              data
              |> Validator.validate()
              |> DataProcessor.process()
              |> tap(&Logger.info("Processed: \#{inspect(&1)}"))
            end
          end

      ## Not Preferred

          defmodule MyModule do
            def process_data(data) do
              alias MyApp.DataProcessor
              alias MyApp.Validator
              require Logger

              data
              |> Validator.validate()
              |> DataProcessor.process()
              |> tap(&Logger.info("Processed: \#{inspect(&1)}"))
            end
          end

      Like all `Readability` issues, this is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.

      ## Rationale

      1. **Discoverability**: All module dependencies are visible at the top of the file
      2. **Consistency**: Predictable module structure across the codebase
      3. **Refactoring**: Easier to move code between functions
      4. **Code Review**: Dependencies are clear in pull request diffs
      5. **Tooling**: Better support for editor jump-to-definition

      ## When to Opt-In

      This check is marked as controversial and disabled by default because some teams
      and use cases legitimately prefer inline directives:

      - **Namespace scoping**: Limiting alias scope to where it's needed
      - **Phoenix LiveView components**: Inline aliases in render functions
      - **Test organization**: Grouping test-specific aliases with tests
      - **Macro hygiene**: Keeping macro-internal dependencies localized

      Enable this check if your team values explicit, discoverable dependencies over
      tightly-scoped imports.

      ## Configuration Example

      To enable this check in your project:

          # In .credo.exs
          {Credo.Check.Readability.StrictModuleDirectiveScope, [
            directives: [:alias, :require],  # Only check these two
            allow_in_private_functions: true,
            exclude_functions: [~r/^render/]  # Allow in LiveView render functions
          ]}
      """,
      params: [
        directives: """
        List of directive types to check. Defaults to all four directives.

        Supported values: `:alias`, `:require`, `:import`, `:use`
        """,
        allow_in_private_functions: """
        When set to `true`, allows module directives inside private functions.

        Some teams prefer to allow inline directives in private functions to keep
        internal implementation details scoped.
        """,
        allow_in_test_macros: """
        When set to `true`, allows module directives inside test macros like
        `setup`, `describe`, and `test`.

        Test code often benefits from localized imports for test-specific helpers.
        """,
        allow_in_quote_blocks: """
        When set to `true`, allows module directives inside `quote` blocks.

        Macros that generate code for their callers often need directives in
        quote blocks. This should generally remain `true`.
        """,
        exclude_functions: """
        List of regular expressions matching function names to exclude from checking.

        Example: `[~r/^render/, ~r/_test$/]` would skip functions starting with
        "render" or ending with "_test".
        """
      ]
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    config = %{
      directives: Params.get(params, :directives, __MODULE__),
      allow_private: Params.get(params, :allow_in_private_functions, __MODULE__),
      allow_test_macros: Params.get(params, :allow_in_test_macros, __MODULE__),
      allow_quote_blocks: Params.get(params, :allow_in_quote_blocks, __MODULE__),
      exclude_functions: Params.get(params, :exclude_functions, __MODULE__)
    }

    issue_meta = IssueMeta.for(source_file, params)

    source_file
    |> Credo.Code.prewalk(&traverse(&1, &2, config, issue_meta))
    |> Enum.sort_by(&{&1.line_no, &1.column})
  end

  # Module definition - don't traverse into nested modules
  defp traverse({:defmodule, _meta, _args} = ast, issues, _config, _issue_meta) do
    {ast, issues}
  end

  # Function definitions (def, defp, defmacro, defmacrop)
  # This is where we check for inline directives
  defp traverse({fun_type, _meta, args} = ast, issues, config, issue_meta)
       when fun_type in [:def, :defp, :defmacro, :defmacrop] and is_list(args) do
    is_private = fun_type in [:defp, :defmacrop]
    fun_name = extract_function_name(args)

    # Skip if configured to allow
    skip_private = is_private and config.allow_private
    skip_excluded = is_excluded_function?(fun_name, config.exclude_functions)

    if skip_private or skip_excluded do
      {ast, issues}
    else
      # Create context for this function
      context = %{
        in_function: {fun_type, fun_name},
        in_test_macro: false,
        in_quote_block: false
      }

      # Find all directive issues in this function's body
      new_issues = find_all_directive_issues(args, config, context, issue_meta)

      # Return nil to prevent prewalk from descending (avoid duplicate detection)
      {nil, new_issues ++ issues}
    end
  end

  # Catch-all: continue traversing
  defp traverse(ast, issues, _config, _issue_meta) do
    {ast, issues}
  end

  # Extract function name from function definition args
  defp extract_function_name([{:when, _, [{name, _, _} | _]} | _]) when is_atom(name), do: name
  defp extract_function_name([{name, _, _} | _]) when is_atom(name), do: name
  defp extract_function_name(_), do: :unknown

  # Check if function name matches any exclusion pattern
  defp is_excluded_function?(_fun_name, []), do: false

  defp is_excluded_function?(fun_name, exclusion_patterns) when is_atom(fun_name) do
    fun_string = Atom.to_string(fun_name)

    Enum.any?(exclusion_patterns, fn
      %Regex{} = pattern -> Regex.match?(pattern, fun_string)
      _ -> false
    end)
  end

  defp is_excluded_function?(_, _), do: false

  # Find all directive issues in function args (handles all clause types)
  defp find_all_directive_issues([_signature | keyword_blocks], config, context, issue_meta)
       when is_list(keyword_blocks) do
    keyword_blocks
    |> List.first([])
    |> Enum.flat_map(fn
      {:do, body} ->
        find_directives_in_body(body, config, context, issue_meta)

      {clause_type, body} when clause_type in [:rescue, :catch, :after, :else] ->
        find_directives_in_body(body, config, context, issue_meta)

      _ ->
        []
    end)
  end

  defp find_all_directive_issues(_, _, _, _), do: []

  # Find directives in a block of code
  defp find_directives_in_body({:__block__, _meta, expressions}, config, context, issue_meta)
       when is_list(expressions) do
    Enum.flat_map(expressions, &check_expression(&1, config, context, issue_meta))
  end

  defp find_directives_in_body(expression, config, context, issue_meta) do
    check_expression(expression, config, context, issue_meta)
  end

  # Check a single expression for directives
  defp check_expression({directive, meta, args}, config, context, issue_meta)
       when directive in [:alias, :require, :import, :use] do
    # Check if we should report this directive
    should_check =
      directive in config.directives and
        not context.in_test_macro and
        not context.in_quote_block

    if should_check do
      [create_issue(directive, meta, args, context.in_function, issue_meta)]
    else
      []
    end
  end

  # Recursively check nested control structures

  # if/unless
  defp check_expression({control, _meta, [_condition, clauses]}, config, context, issue_meta)
       when control in [:if, :unless] do
    check_clauses(clauses, config, context, issue_meta)
  end

  # case
  defp check_expression({:case, _meta, [_value, [do: clauses]]}, config, context, issue_meta) do
    Enum.flat_map(clauses, fn {:->, _, [_pattern, body]} ->
      find_directives_in_body(body, config, context, issue_meta)
    end)
  end

  # cond
  defp check_expression({:cond, _meta, [[do: clauses]]}, config, context, issue_meta) do
    Enum.flat_map(clauses, fn {:->, _, [_condition, body]} ->
      find_directives_in_body(body, config, context, issue_meta)
    end)
  end

  # with
  defp check_expression({:with, _meta, args}, config, context, issue_meta) do
    {clauses, do_else} = Enum.split_while(args, fn arg -> not is_list(arg) end)

    do_else_issues =
      case do_else do
        [[do: do_body]] ->
          find_directives_in_body(do_body, config, context, issue_meta)

        [[do: do_body, else: else_clauses]] ->
          find_directives_in_body(do_body, config, context, issue_meta) ++
            Enum.flat_map(else_clauses, fn {:->, _, [_pattern, body]} ->
              find_directives_in_body(body, config, context, issue_meta)
            end)

        _ ->
          []
      end

    # Also check in with clause bodies (right side of <-)
    clause_issues =
      Enum.flat_map(clauses, fn
        {:<-, _meta, [_left, right]} ->
          find_directives_in_body(right, config, context, issue_meta)

        _other ->
          []
      end)

    clause_issues ++ do_else_issues
  end

  # try
  defp check_expression({:try, _meta, [[do: do_body] ++ other_clauses]}, config, context, issue_meta) do
    do_issues = find_directives_in_body(do_body, config, context, issue_meta)

    other_issues =
      Enum.flat_map(other_clauses, fn
        {:rescue, rescue_clauses} ->
          Enum.flat_map(rescue_clauses, fn {:->, _, [_pattern, body]} ->
            find_directives_in_body(body, config, context, issue_meta)
          end)

        {:catch, catch_clauses} ->
          Enum.flat_map(catch_clauses, fn {:->, _, [_pattern, body]} ->
            find_directives_in_body(body, config, context, issue_meta)
          end)

        {:after, after_body} ->
          find_directives_in_body(after_body, config, context, issue_meta)

        {:else, else_clauses} ->
          Enum.flat_map(else_clauses, fn {:->, _, [_pattern, body]} ->
            find_directives_in_body(body, config, context, issue_meta)
          end)

        _ ->
          []
      end)

    do_issues ++ other_issues
  end

  # Quote blocks - update context
  defp check_expression({:quote, _meta, quote_args}, config, context, issue_meta) do
    if config.allow_quote_blocks do
      []
    else
      # Check inside quote with updated context
      new_context = %{context | in_quote_block: true}

      case quote_args do
        [_opts, [do: body]] -> find_directives_in_body(body, config, new_context, issue_meta)
        [[do: body]] -> find_directives_in_body(body, config, new_context, issue_meta)
        _ -> []
      end
    end
  end

  # Test macros - update context
  defp check_expression({test_macro, _meta, macro_args}, config, context, issue_meta)
       when test_macro in [:setup, :setup_all, :test, :describe] do
    if config.allow_test_macros do
      []
    else
      # Check inside test macro with updated context
      new_context = %{context | in_test_macro: true}

      case macro_args do
        [_name, [do: body]] -> find_directives_in_body(body, config, new_context, issue_meta)
        [[do: body]] -> find_directives_in_body(body, config, new_context, issue_meta)
        _ -> []
      end
    end
  end

  # Anonymous functions
  defp check_expression({:fn, _meta, clauses}, config, context, issue_meta) do
    Enum.flat_map(clauses, fn {:->, _, [_params, body]} ->
      find_directives_in_body(body, config, context, issue_meta)
    end)
  end

  # for comprehensions
  defp check_expression({:for, _meta, args}, config, context, issue_meta) do
    case List.last(args) do
      [do: body] -> find_directives_in_body(body, config, context, issue_meta)
      _ -> []
    end
  end

  # Other expressions - don't check
  defp check_expression(_other, _config, _context, _issue_meta) do
    []
  end

  # Check clauses (for if/unless)
  defp check_clauses(clauses, config, context, issue_meta) do
    Enum.flat_map(clauses, fn
      {:do, body} -> find_directives_in_body(body, config, context, issue_meta)
      {:else, body} -> find_directives_in_body(body, config, context, issue_meta)
      _ -> []
    end)
  end

  # Create issue for a directive found in a function
  defp create_issue(directive, meta, args, {fun_type, fun_name}, issue_meta) do
    directive_name = directive_display_name(directive, args)
    fun_description = function_description(fun_type, fun_name)

    format_issue(issue_meta,
      message:
        "#{directive_name} should be defined at module level, not inside #{fun_description}",
      line_no: meta[:line],
      column: meta[:column],
      trigger: Atom.to_string(directive)
    )
  end

  # Get display name for directive (e.g., "Alias Foo.Bar" or "Require Logger")
  defp directive_display_name(directive, args) do
    module_name =
      case args do
        [{:__aliases__, _, aliases} | _] ->
          aliases |> Enum.map(&Atom.to_string/1) |> Enum.join(".")

        [{:__aliases__, _, aliases}, _opts | _] ->
          aliases |> Enum.map(&Atom.to_string/1) |> Enum.join(".")

        [atom | _] when is_atom(atom) ->
          Atom.to_string(atom)

        _ ->
          ""
      end

    directive_str = directive |> Atom.to_string() |> String.capitalize()

    if module_name != "" do
      "#{directive_str} #{module_name}"
    else
      directive_str
    end
  end

  # Get human-readable function description
  defp function_description(fun_type, fun_name) do
    type_str =
      case fun_type do
        :defp -> "private function"
        :defmacrop -> "private macro"
        :defmacro -> "macro"
        :def -> "function"
        _ -> "function"
      end

    "#{type_str} #{fun_name}"
  end
end
