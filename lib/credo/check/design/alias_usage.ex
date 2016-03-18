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

  # Ignore multi alias call
  defp traverse({:., _, [{:__aliases__, meta, mod_list}, :{}]} = ast, issues, _source_file, _excluded_namespaces, _excluded_lastnames) do
    {ast, issues}
  end
  defp traverse({:., _, [{:__aliases__, meta, mod_list}, fun_atom]} = ast, issues, issue_meta, excluded_namespaces, excluded_lastnames) when is_list(mod_list) and is_atom(fun_atom) do
    if Enum.count(mod_list) > 1 && !Enum.any?(mod_list, &tuple?/1) do
      first_name = mod_list |> List.first |> to_string
      last_name = mod_list |> List.last |> to_string
      if !Enum.member?(excluded_namespaces, first_name) && !Enum.member?(excluded_lastnames, last_name) do
        trigger = mod_list |> Enum.join(".")
        IO.inspect fun_atom
        {ast, issues ++ [issue_for(issue_meta, meta[:line], trigger)]}
      else
        {ast, issues}
      end
    else
      {ast, issues}
    end
  end
  defp traverse(ast, issues, _source_file, _excluded_namespaces, _excluded_lastnames) do
    {ast, issues}
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
