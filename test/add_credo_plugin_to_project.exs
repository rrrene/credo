defmodule AstHelper do
  def update(ast, fun) do
    case fun.(ast) do
      {atom, meta, list} when is_list(list) ->
        {atom, meta, Enum.map(list, &update(&1, fun))}

      list when is_list(list) ->
        Enum.map(list, &update(&1, fun))

      {key, value} ->
        {key, update(value, fun)}

      ast ->
        ast
    end
  end
end

defmodule MixExsFile do
  def add_dependency(filename, dep_name, requirement \\ ">= 0.0.0") do
    new_dep_entry = {String.to_atom(dep_name), requirement}

    content =
      filename
      |> File.read!()
      |> Code.string_to_quoted!()
      |> AstHelper.update(fn
        {:defp, _, [{:deps, _, _}, [_ | _]]} = ast2 ->
          AstHelper.update(ast2, fn
            {:do, list_of_deps} ->
              list_of_deps_without_dep_name =
                Enum.reject(list_of_deps, &(to_string(elem(&1, 0)) == dep_name))

              {:do, list_of_deps_without_dep_name ++ [new_dep_entry]}

            value ->
              value
          end)

        ast3 ->
          ast3
      end)
      |> Macro.to_string()
      |> Code.format_string!()

    File.write(filename, content)
  end
end

defmodule CredoExsFile do
  @default_config """
  %{
    configs: [
      %{
        name: "default"
      }
    ]
  }
  """

  def add_plugin(filename, plugin_name, plugin_params \\ []) do
    if !File.exists?(filename) do
      File.write(filename, @default_config)
    end

    content =
      filename
      |> File.read!()
      |> Code.string_to_quoted!()
      |> AstHelper.update(fn
        {:%{}, meta, arguments} = ast1 ->
          if arguments[:name] == "default" do
            new_plugins = [{:"Elixir.#{plugin_name}", plugin_params}]

            plugins_without_new_plugin =
              Enum.reject(
                List.wrap(arguments[:plugins]),
                &(Macro.to_string(elem(&1, 0)) == plugin_name)
              )

            new_arguments =
              Keyword.update(
                arguments,
                :plugins,
                new_plugins,
                fn _ -> plugins_without_new_plugin ++ new_plugins end
              )

            {:%{}, meta, new_arguments}
          else
            ast1
          end

        ast2 ->
          ast2
      end)
      |> Macro.to_string()
      |> Code.format_string!()

    File.write(filename, content)
  end
end

defmodule Options do
  def parse(argv) do
    {parsed, [], []} =
      OptionParser.parse(argv,
        strict: [project: :string, plugin_package: :string, plugin_name: :string]
      )

    options = Enum.into(parsed, %{})

    options
    |> Map.put(:project, options[:project] || ".")
    |> Map.put(:plugin_name, options[:plugin_name] || Macro.camelize(options[:plugin_package]))
  end
end

options =
  Options.parse(System.argv())
  |> IO.inspect(label: "Arguments given")

project_dir = Path.expand(options.project)
mix_filename = Path.join(project_dir, "mix.exs")
credo_filename = Path.join(project_dir, ".credo.exs")

MixExsFile.add_dependency(mix_filename, options.plugin_package)
CredoExsFile.add_plugin(credo_filename, options.plugin_name)
