defmodule Credo.Check.Refactor.ModuleDependencies do
  use Credo.Check,
    base_priority: :normal,
    tags: [:controversial],
    param_defaults: [
      max_deps: 10,
      dependency_namespaces: [],
      excluded_namespaces: [],
      excluded_paths: [~r"/test/", ~r"^test/"]
    ],
    explanations: [
      check: """
      This module might be doing too much. Consider limiting the number of
      module dependencies.

      As always: This is just a suggestion. Check the configuration options for
      tweaking or disabling this check.
      """,
      params: [
        max_deps: "Maximum number of module dependencies.",
        dependency_namespaces: "List of dependency namespaces to include in this check",
        excluded_namespaces: "List of namespaces to exclude from this check",
        excluded_paths: "List of paths or regex to exclude from this check"
      ]
    ]

  alias Credo.Code.Module
  alias Credo.Code.Name

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    max_deps = Params.get(params, :max_deps, __MODULE__)
    dependency_namespaces = Params.get(params, :dependency_namespaces, __MODULE__)
    excluded_namespaces = Params.get(params, :excluded_namespaces, __MODULE__)
    excluded_paths = Params.get(params, :excluded_paths, __MODULE__)

    case ignore_path?(source_file.filename, excluded_paths) do
      true ->
        []

      false ->
        Credo.Code.prewalk(
          source_file,
          &traverse(
            &1,
            &2,
            issue_meta,
            dependency_namespaces,
            excluded_namespaces,
            max_deps
          )
        )
    end
  end

  # Check if analyzed module path is within ignored paths
  defp ignore_path?(filename, excluded_paths) do
    directory = Path.dirname(filename)

    Enum.any?(excluded_paths, &matches?(directory, &1))
  end

  defp matches?(directory, %Regex{} = regex), do: Regex.match?(regex, directory)
  defp matches?(directory, path) when is_binary(path), do: String.starts_with?(directory, path)

  defp traverse(
         {:defmodule, meta, [mod | _]} = ast,
         issues,
         issue_meta,
         dependency_namespaces,
         excluded_namespaces,
         max
       ) do
    module_name = Name.full(mod)

    new_issues =
      if has_namespace?(module_name, excluded_namespaces) do
        []
      else
        module_dependencies = get_dependencies(ast, dependency_namespaces)

        issues_for_module(module_dependencies, max, issue_meta, meta)
      end

    {ast, issues ++ new_issues}
  end

  defp traverse(ast, issues, _issues_meta, _dependency_namespaces, _excluded_namespaces, _max) do
    {ast, issues}
  end

  defp get_dependencies(ast, dependency_namespaces) do
    aliases = Module.aliases(ast)

    ast
    |> Module.modules()
    |> with_fullnames(aliases)
    |> filter_namespaces(dependency_namespaces)
  end

  defp issues_for_module(deps, max_deps, issue_meta, meta) when length(deps) > max_deps do
    [
      format_issue(
        issue_meta,
        message: "Module has too many dependencies: #{length(deps)} (max is #{max_deps})",
        trigger: deps,
        line_no: meta[:line],
        column_no: meta[:column]
      )
    ]
  end

  defp issues_for_module(_, _, _, _), do: []

  # Resolve dependencies to full module names
  defp with_fullnames(dependencies, aliases) do
    dependencies
    |> Enum.map(&full_name(&1, aliases))
    |> Enum.uniq()
  end

  # Keep only dependencies which are within specified namespaces
  defp filter_namespaces(dependencies, namespaces) do
    Enum.filter(dependencies, &keep?(&1, namespaces))
  end

  defp keep?(_module_name, []), do: true

  defp keep?(module_name, namespaces), do: has_namespace?(module_name, namespaces)

  defp has_namespace?(module_name, namespaces) do
    Enum.any?(namespaces, &String.starts_with?(module_name, &1))
  end

  # Get full module name from list of aliases (if present)
  defp full_name(dep, aliases) do
    aliases
    |> Enum.find(&String.ends_with?(&1, dep))
    |> case do
      nil -> dep
      full_name -> full_name
    end
  end
end
