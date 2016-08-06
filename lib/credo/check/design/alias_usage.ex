defmodule Credo.Check.Design.AliasUsage do
  @moduledoc """
  Functions from other modules should be used via an alias if the module's
  namespace is not top-level.

  While this is completely fine:

      defmodule MyApp.Web.Search do
        def twitter_mentions do
          MyApp.External.TwitterAPI.search(...)
        end
      end

  ... you might want to refactor it to look like this:

      defmodule MyApp.Web.Search do
        alias MyApp.External.TwitterAPI

        def twitter_mentions do
          TwitterAPI.search(...)
        end
      end

  The thinking behind this is that you can see the dependencies of your module
  at a glance. So if you are attempting to build a medium to large project,
  this can help you to get your boundaries/layers/contracts right.

  Like all `Software Design` issues, this is just advice and might not be
  applicable to your project/situation.
  """

  @explanation [check: @moduledoc]
  @default_params [
      excluded_namespaces: [
        "File",
        "IO",
        "Inspect",
        "Kernel",
        "Macro",
        "Supervisor",
        "Task",
        "Version"
      ],
      excluded_lastnames:  ~w[Access Agent Application Atom Base Behaviour
                              Bitwise Code Dict Enum Exception File Float
                              GenEvent GenServer HashDict HashSet IO Integer
                              Kernel Keyword List Macro Map MapSet Module Node
                              OptionParser Path Port Process Protocol Range
                              Record Regex Set Stream String StringIO Supervisor
                              System Task Tuple URI Version]
    ]

  use Credo.Check, base_priority: :normal

  @doc false
  def run(%SourceFile{ast: ast} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    excluded_namespaces = params |> Params.get(:excluded_namespaces, @default_params)
    excluded_lastnames = params |> Params.get(:excluded_lastnames, @default_params)

    Credo.Code.prewalk(ast, &traverse(&1, &2, issue_meta, excluded_namespaces, excluded_lastnames))
  end

  defp traverse({:defmodule, _, _} = ast, issues, issue_meta, excluded_namespaces, excluded_lastnames) do
    aliases = Credo.Code.Module.aliases(ast)
    mod_deps = Credo.Code.Module.modules(ast)
    new_issues = Credo.Code.prewalk(ast, &find_issues(&1, &2, issue_meta, excluded_namespaces, excluded_lastnames, aliases, mod_deps))
    {ast, issues ++ new_issues}
  end
  defp traverse(ast, issues, _source_file, _excluded_namespaces, _excluded_lastnames) do
    {ast, issues}
  end

  # Ignore module attributes
  defp find_issues({:@, _, _}, issues, _, _, _, _, _) do
    {nil, issues}
  end
  # Ignore multi alias call
  defp find_issues({:., _, [{:__aliases__, _, _}, :{}]} = ast, issues, _, _, _, _, _) do
    {ast, issues}
  end
  defp find_issues({:., _, [{:__aliases__, meta, mod_list}, fun_atom]} = ast, issues, issue_meta, excluded_namespaces, excluded_lastnames, aliases, mod_deps) when is_list(mod_list) and is_atom(fun_atom) do
    cond do
      (Enum.count(mod_list) <= 1 || Enum.any?(mod_list, &tuple?/1)) ->
        {ast, issues}
      excluded_lastname_or_namespace?(mod_list, excluded_namespaces, excluded_lastnames) ->
        {ast, issues}
      conflicting_with_aliases?(mod_list, aliases) ->
        {ast, issues}
      conflicting_with_other_modules?(mod_list, mod_deps) ->
        {ast, issues}
      true ->
        trigger = mod_list |> Enum.join(".")
        {ast, issues ++ [issue_for(issue_meta, meta[:line], trigger)]}
    end
  end
  defp find_issues(ast, issues, _, _, _, _, _) do
    {ast, issues}
  end

  defp excluded_lastname_or_namespace?(mod_list, excluded_namespaces, excluded_lastnames) do
    first_name = mod_list |> Credo.Code.Name.first
    last_name = mod_list |> Credo.Code.Name.last

    Enum.member?(excluded_namespaces, first_name) ||
    Enum.member?(excluded_lastnames, last_name)
  end

  # Returns true if mod_list and alias_name would result in the same alias
  # since they share the same last name.
  defp conflicting_with_aliases?(mod_list, aliases) do
    last_name = mod_list |> Credo.Code.Name.last

    aliases |> Enum.find(&conflicting_alias?(&1, mod_list, last_name))
  end
  defp conflicting_alias?(alias_name, mod_list, last_name) do
    full_name = mod_list |> Credo.Code.Name.full
    alias_last_name = alias_name |> Credo.Code.Name.last

    full_name != alias_name && alias_last_name == last_name
  end

  # Returns true if mod_list and any dependent module would result in the same alias
  # since they share the same last name.
  defp conflicting_with_other_modules?(mod_list, mod_deps) do
    last_name = mod_list |> Credo.Code.Name.last
    full_name = mod_list |> Credo.Code.Name.full

    (mod_deps -- [full_name])
    |> Enum.filter(&Credo.Code.Name.parts_count(&1) > 1)
    |> Enum.map(&Credo.Code.Name.last/1)
    |> Enum.any?(&(&1 == last_name))
  end

  def tuple?(t) when is_tuple(t), do: true
  def tuple?(_), do: false

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue issue_meta,
      message: "Nested modules could be aliased at the top of the invoking module.",
      trigger: trigger,
      line_no: line_no
  end
end
