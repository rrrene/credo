defmodule Credo.Check.Design.AliasOnlyToBoundaries do
  use Credo.Check,
    base_priority: :normal,
    explanations: [
      check: """
      When defining aliases to other modules you don't need to alias directly to other modules.
      For example:

          alias MyApp.Accounts.User
          # From here you would refer to `User`

          alias MyApp.Accounts
          # From here you would refer to `Accounts.User`

      If you are inside of a particular module namespace, aliasing directly to other modules can be
      very useful. But when aliasing directly to modules which are outside of the current namespace,
      you can lose the context of which module is being used in your code

      In this example we are in the `MyApp.Accounts.Access` module. Referencing `User` directly
      makes sense because it's in the `MyApp.Accounts` namespace, but `Post` is outside of `MyApp.Accounts`:

          defmodule MyApp.Accounts.Access do
            alias MyApp.Accounts.User
            alias MyApp.Posts.Post

            def owns?(%User{} = user, %Post{} = post) do
              # ...
            end

      If the alias is made at a higher level, you then need to refer to the context in your code, helping
      to make clear where the module is coming from:

          defmodule MyApp.Accounts.Access do
            alias MyApp.Accounts.User
            alias MyApp.Posts

            def owns?(%User{} = user, %Posts.Post{} = post) do
              # ...

      This doesn't apply to just the top level namespaces either. For example:

          defmodule MyAppWeb.GraphQL.Schema.Posts.Resolvers do
            # `MyAppWeb.GraphQL` is the shared path in the current module
            # and the examples below.

            # Aliasing `DepthLimiter` directly removes the context
            # of where it came from. Looking at the code, it will likely
            # be difficult to figure out that `DepthLimiter` is a middleware
            # module.
            alias MyAppWeb.GraphQL.Middleware.DepthLimiter

            # Going one level up requires us to refer to `Middleware.DepthLimiter`,
            # making it clear that `DepthLimiter` is a middleware module.
            alias MyAppWeb.GraphQL.Middleware

            # What about the following?  It would be allowed by this check:
            alias MyAppWeb.GraphQL.Schema.Posts

            # ...but if there is also another alias to an app logic namespace module:
            alias MyApp.Posts

            # You might choose to provide an alias one level higher:
            alias MyAppWeb.GraphQL.Schema

            # Then it is clearer that `Schema.Posts` is a GraphQL schema module,
            # and `Posts` is the app logic namespace module.

      Lastly, it is not uncommon to have modules in two different namespaces with the same name.
      For example `MyApp.Accounts.User` and `MyApp.Billing.User`. These two modules might be
      structs/schemas representing the same database table or they might be business logic for
      users in different domains. This check can help make sure it is clear which version
      you are referring to.
      """,
      params: [
        if_shared_namespace_deeper_than:
          "Only enforce check if the shared namespace between the module and the alias is more than N parts (e.g. A.B.C.D and A.B.E.F have a shared namespace of A.B, which is two parts)",
        exceptions:
          "A list of modules (full paths) which are except from this check. Candidates for this may be modules which are used exceptionally often"
      ]
    ],
    param_defaults: [
      if_shared_namespace_deeper_than: 0,
      exceptions: []
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(
      source_file,
      &traverse(&1, &2, issue_meta, params)
    )
  end

  defp traverse(
         {:defmodule, _, _} = ast,
         issues,
         issue_meta,
         params
       ) do
    mod_name = Credo.Code.Module.name(ast)

    module_name_parts =
      mod_name
      |> String.split(".")
      |> Enum.map(&String.to_atom/1)

    alias_declarations =
      ast
      |> Credo.Code.prewalk(fn ast, previous ->
        {ast, previous ++ find_alias_declarations(ast)}
      end)

    module_references =
      ast
      |> Credo.Code.prewalk(fn ast, previous ->
        # dbg()

        case find_module_references(ast) do
          {:ok, next} ->
            {ast, previous ++ next}

          {:skip, new_ast} ->
            {new_ast, previous}
        end
      end)

    new_issues =
      alias_declarations
      |> Enum.map(fn %{parts: parts, meta: meta, as: _as} ->
        issue_for(issue_meta, module_name_parts, meta, parts, params)
      end)

    new_issues =
      new_issues ++
        Enum.map(module_references, fn module_reference ->
          suggest_alias_issue(issue_meta, module_name_parts, module_reference, alias_declarations)
        end)

    new_issues = Enum.reject(new_issues, &is_nil/1)

    {ast, issues ++ new_issues}
  end

  defp traverse(
         ast,
         issues,
         _issue_meta,
         _if_shared_namespace_deeper_than
       ) do
    {ast, issues}
  end

  # Ignore module attributes
  defp find_alias_declarations({:@, _, _}) do
    []
  end

  # Ignore alias containing an `unquote` call
  defp find_alias_declarations({:., _, [{:__aliases__, _, mod_list}, :unquote]})
       when is_list(mod_list) do
    []
  end

  # Multi-alias
  # i.e. alias Foo.Bar.{Biz, Baz}
  defp find_alias_declarations(
         {:alias, _meta1,
          [
            {{:., _meta2, [{:__aliases__, _meta, alias_base_parts}, :{}]}, _meta3, alias_suffixes}
          ]}
       ) do
    Enum.map(alias_suffixes, fn {:__aliases__, meta, suffix_parts} ->
      %{
        parts: alias_parts = alias_base_parts ++ suffix_parts,
        meta: meta,
        as: nil
      }
    end)
  end

  defp find_alias_declarations({:alias, _meta, [{:__aliases__, meta, alias_parts}]}) do
    [%{parts: alias_parts, meta: meta, as: nil}]
  end

  # alias with `as` option
  defp find_alias_declarations(
         {:alias, _,
          [
            {:__aliases__, meta, alias_parts},
            [as: {:__aliases__, _, _}]
          ]}
       ) do
    [%{parts: alias_parts, meta: meta, as: nil}]
  end

  defp find_alias_declarations(_ast) do
    []
  end

  def find_module_references(
        {:defmodule, _,
         [
           {:__aliases__, _, _},
           body_ast
         ]}
      ) do
    {:skip, body_ast}
  end

  def find_module_references({:alias, _, [_ | _]}) do
    {:skip, nil}
  end

  def find_module_references({:__aliases__, meta, path}) do
    {:ok, [%{path: path, meta: meta}]}
  end

  def find_module_references(_ast) do
    {:ok, []}
  end

  defp issue_for(
         issue_meta,
         module_name_parts,
         meta,
         alias_parts,
         params
       ) do
    common_parts = common_parts(module_name_parts, alias_parts)

    too_deep? = length(alias_parts) > length(common_parts) + 1
    shared_namespace_too_deep? = length(common_parts) >= if_shared_namespace_deeper_than(params)
    exempted? = Enum.join(alias_parts, ".") in exceptions(params)

    if too_deep? && shared_namespace_too_deep? && !exempted? do
      suggested_path = Enum.take(alias_parts, length(common_parts) + 1)

      format_issue(
        issue_meta,
        message:
          "You are aliasing too far into another module: #{Enum.join(alias_parts, ".")} (suggestion: `alias #{Enum.join(suggested_path, ".")}`)",
        trigger: Enum.join(module_name_parts, "."),
        line_no: meta[:line]
      )
    end
  end

  def suggest_alias_issue(
        issue_meta,
        module_name_parts,
        %{path: module_reference_path, meta: module_reference_meta},
        alias_declarations
      ) do
    used_alias_declaration =
      Enum.find(alias_declarations, fn alias_declaration ->
        List.last(alias_declaration.parts) == List.first(module_reference_path)
      end)

    if used_alias_declaration do
      actual_module_reference_path =
        used_alias_declaration.parts ++ List.delete_at(module_reference_path, 0)

      common_parts = common_parts(module_name_parts, actual_module_reference_path)

      suggested_path = Enum.take(actual_module_reference_path, length(common_parts) + 1)

      # dbg()

      if used_alias_declaration.parts != suggested_path do
        format_issue(
          issue_meta,
          message:
            "Nested modules could be aliased at the top of the invoking module. (suggestion: `alias #{Enum.join(suggested_path, ".")}`)",
          trigger: Enum.join(module_name_parts, "."),
          line_no: module_reference_meta[:line]
        )
      end
    else
      common_parts = common_parts(module_name_parts, module_reference_path)

      if length(common_parts) > 0 do
        suggested_path = Enum.take(module_reference_path, length(common_parts) + 1)

        format_issue(
          issue_meta,
          message:
            "Nested modules could be aliased at the top of the invoking module. (suggestion: `alias #{Enum.join(suggested_path, ".")}`)",
          trigger: Enum.join(module_name_parts, "."),
          line_no: module_reference_meta[:line]
        )
      end
    end
  end

  defp common_parts(module_parts1, module_parts2) do
    module_parts1
    |> Enum.zip(module_parts2)
    |> Enum.reduce_while([], fn
      {part, part}, result -> {:cont, [part | result]}
      _, result -> {:halt, result}
    end)
    |> Enum.reverse()
  end

  defp if_shared_namespace_deeper_than(params) do
    Params.get(params, :if_shared_namespace_deeper_than, __MODULE__)
  end

  defp exceptions(params) do
    Params.get(params, :exceptions, __MODULE__)
  end
end
