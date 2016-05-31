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

    Credo.Code.traverse(ast, &traverse(&1, &2, issue_meta, excluded_namespaces, excluded_lastnames))
  end

  defp traverse({:defmodule, _, _} = ast, issues, issue_meta, excluded_namespaces, excluded_lastnames) do
    aliases = Credo.Code.traverse(ast, &find_aliases/2)
    new_issues = Credo.Code.traverse(ast, &find_alias_usage(&1, &2, issue_meta, excluded_namespaces, excluded_lastnames, aliases))
    {ast, issues ++ new_issues}
  end
  defp traverse(ast, issues, _source_file, _excluded_namespaces, _excluded_lastnames) do
    {ast, issues}
  end

  # Ignore multi alias call
  defp find_alias_usage({:., _, [{:__aliases__, _, _}, :{}]} = ast, issues, _issue_meta, _excluded_namespaces, _excluded_lastnames, _aliases) do
    {ast, issues}
  end
  defp find_alias_usage({:., _, [{:__aliases__, meta, mod_list}, fun_atom]} = ast, issues, issue_meta, excluded_namespaces, excluded_lastnames, aliases) when is_list(mod_list) and is_atom(fun_atom) do
    if Enum.count(mod_list) > 1 && !Enum.any?(mod_list, &tuple?/1) do
      first_name = mod_list |> List.first |> to_string
      last_name = mod_list |> List.last |> to_string
      excluded? =
        Enum.member?(excluded_namespaces, first_name) ||
        Enum.member?(excluded_lastnames, last_name)

      if excluded? do
        {ast, issues}
      else
        conflicting_alias =
          aliases
          |> Enum.find(&conflicting_alias?(&1, mod_list))

        if conflicting_alias do
          {ast, issues}
        else
          trigger = mod_list |> Enum.join(".")
          {ast, issues ++ [issue_for(issue_meta, meta[:line], trigger)]}
        end
      end
    else
      {ast, issues}
    end
  end
  defp find_alias_usage(ast, issues, _source_file, _excluded_namespaces, _excluded_lastnames, _aliases) do
    {ast, issues}
  end

  # Returns true if mod_list and alias_name would result in the same alias
  # since they share the same last name.
  defp conflicting_alias?(alias_name, mod_list) do
    last_name = mod_list |> List.last |> to_string
    full_name = mod_list |> to_module_name
    alias_last_name = alias_name |> String.split(".") |> List.last

    full_name != alias_name && alias_last_name == last_name
  end

  # Single alias
  defp find_aliases({:alias, _, [{:__aliases__, _, mod_list}]} = ast, aliases) do
    module_names = mod_list |> to_module_name |> List.wrap
    {ast, aliases ++ module_names}
  end
  # Multi alias
  defp find_aliases({:alias, _, [{{:., _, [{:__aliases__, _, mod_list}, :{}]}, _, multi_mod_list}]} = ast, aliases) do
    module_names =
      multi_mod_list
      |> Enum.map(fn(tuple) ->
          [to_module_name(mod_list), to_module_name(tuple)] |> to_module_name
        end)

    {ast, aliases ++ module_names}
  end
  defp find_aliases(ast, aliases) do
    {ast, aliases}
  end

  def tuple?(t) when is_tuple(t), do: true
  def tuple?(_), do: false

  defp to_module_name(mod_list) when is_list(mod_list) do
    mod_list
    |> Enum.map(&to_module_name/1)
    |> Enum.join(".")
  end
  defp to_module_name({:__aliases__, _, mod_list}) do
    mod_list |> to_module_name()
  end
  defp to_module_name({name, _, nil}) when is_atom(name) do
    name |> to_module_name
  end
  defp to_module_name(name) when is_binary(name) or is_atom(name) do
    name
  end


  defp issue_for(issue_meta, line_no, trigger) do
    format_issue issue_meta,
      message: "Nested modules could be aliased at the top of the invoking module.",
      trigger: trigger,
      line_no: line_no
  end
end
