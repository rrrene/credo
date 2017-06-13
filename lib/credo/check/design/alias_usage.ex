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

  As always: This is just a suggestion. Check the configuration options for
  tweaking or disabling this check.
  """

  @explanation [
    check: @moduledoc,
    params: [
      if_nested_deeper_than: "Only raise an issue if a module is nested deeper than this.",
      if_called_more_often_than: "Only raise an issue if a module is called more often than this.",
    ]
  ]
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
                              Bitwise Code Date DateTime Dict Enum Exception
                              File Float GenEvent GenServer HashDict HashSet
                              Integer IO Kernel Keyword List Macro Map MapSet
                              Module NaiveDateTime Node OptionParser Path Port
                              Process Protocol Range Record Regex Registry Set
                              Stream String StringIO Supervisor System Task Time
                              Tuple URI Version],
      if_nested_deeper_than: 0,
      if_called_more_often_than: 0,
    ]

  use Credo.Check, base_priority: :normal

  alias Credo.Code.Name

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    excluded_namespaces = Params.get(params, :excluded_namespaces, @default_params)
    excluded_lastnames = Params.get(params, :excluded_lastnames, @default_params)
    if_nested_deeper_than = Params.get(params, :if_nested_deeper_than, @default_params)
    if_called_more_often_than = Params.get(params, :if_called_more_often_than, @default_params)

    source_file
    |> Credo.Code.prewalk(&traverse(&1, &2, issue_meta, excluded_namespaces, excluded_lastnames))
    |> filter_issues_if_called_more_often_than(if_called_more_often_than)
    |> filter_issues_if_nested_deeper_than(if_nested_deeper_than)
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
        trigger = Enum.join(mod_list, ".")

        {ast, issues ++ [issue_for(issue_meta, meta[:line], trigger)]}
    end
  end
  defp find_issues(ast, issues, _, _, _, _, _) do
    {ast, issues}
  end

  defp excluded_lastname_or_namespace?(mod_list, excluded_namespaces, excluded_lastnames) do
    first_name = Credo.Code.Name.first(mod_list)
    last_name = Credo.Code.Name.last(mod_list)

    Enum.member?(excluded_namespaces, first_name) ||
      Enum.member?(excluded_lastnames, last_name)
  end

  # Returns true if mod_list and alias_name would result in the same alias
  # since they share the same last name.
  defp conflicting_with_aliases?(mod_list, aliases) do
    last_name = Credo.Code.Name.last(mod_list)

    Enum.find(aliases, &conflicting_alias?(&1, mod_list, last_name))
  end
  defp conflicting_alias?(alias_name, mod_list, last_name) do
    full_name = Credo.Code.Name.full(mod_list)
    alias_last_name = Credo.Code.Name.last(alias_name)

    full_name != alias_name && alias_last_name == last_name
  end

  # Returns true if mod_list and any dependent module would result in the same alias
  # since they share the same last name.
  defp conflicting_with_other_modules?(mod_list, mod_deps) do
    last_name = Credo.Code.Name.last(mod_list)
    full_name = Credo.Code.Name.full(mod_list)

    (mod_deps -- [full_name])
    |> Enum.filter(&Credo.Code.Name.parts_count(&1) > 1)
    |> Enum.map(&Credo.Code.Name.last/1)
    |> Enum.any?(&(&1 == last_name))
  end

  defp tuple?(t) when is_tuple(t), do: true
  defp tuple?(_), do: false

  defp filter_issues_if_called_more_often_than(issues, count) do
    issues
    |> Enum.reduce(%{}, fn(issue, memo) ->
        list = memo[issue.trigger] || []

        Map.put(memo, issue.trigger, [issue | list])
      end)
    |> Enum.filter(fn({_, value}) ->
        length(value) > count
      end)
    |> Enum.map(fn({_, value}) ->
      value
    end)
    |> List.flatten
  end

  defp filter_issues_if_nested_deeper_than(issues, count) do
    Enum.filter(issues, fn(issue) ->
      Name.parts_count(issue.trigger) > count
    end)
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue issue_meta,
      message: "Nested modules could be aliased at the top of the invoking module.",
      trigger: trigger,
      line_no: line_no
  end
end
