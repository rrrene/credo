defmodule Credo.Check.Readability.ModuleDoc do
  use Credo.Check,
    id: "EX3009",
    param_defaults: [
      ignore_names: [
        ~r/(\.\w+Controller|\.Endpoint|\.\w+Live(\.\w+)?|\.Repo|\.Router|\.\w+Socket|\.\w+View|\.\w+HTML|\.\w+JSON|\.Telemetry|\.Layouts|\.Mailer)$/
      ],
      ignore_modules_using: []
    ],
    explanations: [
      check: """
      Every module should contain comprehensive documentation.

          # preferred

          defmodule MyApp.Web.Search do
            @moduledoc \"\"\"
            This module provides a public API for all search queries originating
            in the web layer.
            \"\"\"
          end

          # also okay: explicitly say there is no documentation

          defmodule MyApp.Web.Search do
            @moduledoc false
          end

      Many times a sentence or two in plain english, explaining why the module
      exists, will suffice. Documenting your train of thought this way will help
      both your co-workers and your future-self.

      Other times you will want to elaborate even further and show some
      examples of how the module's functions can and should be used.

      In some cases however, you might not want to document things about a module,
      e.g. it is part of a private API inside your project. Since Elixir prefers
      explicitness over implicit behaviour, you should "tag" these modules with

          @moduledoc false

      to make it clear that there is no intention in documenting it.

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """,
      params: [
        ignore_names:
          "List of modules to ignore based on their name. Accepts atoms, strings and regexes.",
        ignore_modules_using:
          "List of modules to ignore based on their `use` declarations. Accepts atoms, strings and regexes."
      ]
    ]

  alias Credo.Code.Module

  @doc false
  def run(%SourceFile{filename: filename} = source_file, params \\ []) do
    if Path.extname(filename) == ".exs" do
      []
    else
      ctx = Context.build(source_file, params, __MODULE__)
      result = Credo.Code.prewalk(source_file, &walk/2, ctx)
      result.issues
    end
  end

  defp walk({:defmodule, _meta, _arguments} = ast, ctx) do
    mod_name = Module.name(ast)

    cond do
      matches_any?(mod_name, ctx.params.ignore_names) ->
        {nil, ctx}

      uses_matching_module?(ast, ctx.params.ignore_modules_using) ->
        {nil, ctx}

      true ->
        handle_moduledoc(ast, mod_name, ctx)
    end
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp handle_moduledoc({:defmodule, meta, _arguments} = ast, mod_name, ctx) do
    exception? = Module.exception?(ast)

    case Module.attribute(ast, :moduledoc) do
      {:error, _} when not exception? ->
        {ast, put_issue(ctx, issue_for(ctx, meta, mod_name, :default))}

      "" <> string ->
        if String.trim(string) == "" do
          {ast, put_issue(ctx, issue_for(ctx, meta, mod_name, :empty))}
        else
          {ast, ctx}
        end

      _ ->
        {ast, ctx}
    end
  end

  defp uses_matching_module?(_ast, []), do: false

  defp uses_matching_module?(ast, ignored_usings) do
    ast
    |> Credo.Code.Block.calls_in_do_block()
    |> Enum.any?(fn
      {:use, _, [{:__aliases__, _, mod_list} | _]} ->
        mod_list
        |> Credo.Code.Name.full()
        |> matches_any?(ignored_usings)

      _ ->
        false
    end)
  end

  defp matches_any?(_name, []), do: false

  defp matches_any?("" <> name, list) when is_list(list) do
    Enum.any?(list, &matches_any?(name, &1))
  end

  defp matches_any?(name, atom) when is_atom(atom) do
    matches_any?(name, Credo.Code.Name.full(atom))
  end

  defp matches_any?(name, string) when is_binary(string) do
    String.contains?(name, string)
  end

  defp matches_any?(name, %Regex{} = regex) do
    String.match?(name, regex)
  end

  defp issue_for(ctx, meta, trigger, :default) do
    issue_for(ctx, meta, trigger, "Modules should have a @moduledoc tag.")
  end

  defp issue_for(ctx, meta, trigger, :empty) do
    issue_for(ctx, meta, trigger, "Use `@moduledoc false` if a module will not be documented.")
  end

  defp issue_for(ctx, meta, trigger, "" <> message) do
    format_issue(ctx, line_no: meta[:line], trigger: trigger, message: message)
  end
end
