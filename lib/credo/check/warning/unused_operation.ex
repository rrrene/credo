defmodule Credo.Check.Warning.UnusedOperation do
  use Credo.Check,
    id: "EX5031",
    base_priority: :high,
    param_defaults: [modules: []],
    explanations: [
      check: """
      The result of a call to some functions has to be used.

      This is a generic check that you can configure to your needs.
      With checks like `UnusedEnumOperation` you can catch instances where you call
      e.g. `Enum.reject/1`, but accidentally do not use the result:

          def prepend_my_username(my_username, usernames) do
            Enum.reject(usernames, &is_nil/1)

            [my_username] ++ usernames
          end

      With this check you can do the same for your modules and functions.
      """,
      params: [
        modules: """
        The modules and functions that should trigger this check.

        Format: `{module, functions}` or `{module, functions, issue_message}`

        `functions` can be a list of functions names as atoms or `:all` to include all functions of `module`.
        """
      ]
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)

    ctx = %{ctx | params: normalize_params(ctx.params)}
    relevant_modules = Enum.map(ctx.params.modules, fn {mod, _fun_list, _message} -> mod end)
    run(source_file, params, relevant_modules, ctx.params.modules, &format_issue/2)
  end

  defp normalize_params(params) do
    modules =
      Enum.map(params.modules, fn
        {mod, fun_list} -> {normalize_mod(mod), fun_list, nil}
        {mod, fun_list, issue_message} -> {normalize_mod(mod), fun_list, issue_message}
      end)

    Map.put(params, :modules, modules)
  end

  defp normalize_mod(mod) do
    mod
    |> Module.split()
    |> Enum.map(&String.to_atom/1)
  end

  # The result of a call to the provided module's functions has to be used.

  alias Credo.Check.Warning.UnusedFunctionReturnHelper
  alias Credo.IssueMeta

  @doc false
  def run(source_file, params \\ [], relevant_module_or_modules, single_mod_funs_or_module_configs, format_issue_fun)

  # Matches calls like:
  #   run(source_file, params, :Enum, [:map, :filter], &format_issue/2)
  #
  # This is what related checks like Credo.Check.Warning.UnusedStringOperation call us directly with.
  def run(source_file, params, single_module, funs, format_issue_fun) when is_atom(single_module) do
    run(source_file, params, [single_module], [{List.wrap(single_module), funs, nil}], format_issue_fun)
  end

  # Matches calls like:
  #   run(source_file, params, [:Enum, :Map], [{:Enum, [:map, :filter]}, {:Map, [:take, :put]}], &format_issue/2)
  #
  # or even:
  #   run(source_file, params, [MyApp.MyModule], [{MyApp.MyModule, [:my_fun]}], &format_issue/2)
  #
  # This is what this check's `run/2` calls us with.
  def run(%SourceFile{} = source_file, params, relevant_modules, module_configs, format_issue_fun) do
    issue_meta = IssueMeta.for(source_file, params)

    all_unused_calls =
      UnusedFunctionReturnHelper.find_unused_calls(
        source_file,
        params,
        relevant_modules,
        nil
      )

    ignored = List.wrap(params[:ignore])

    all_unused_calls
    |> Enum.reject(fn {{:., _, [{:__aliases__, _, _}, fun_name]}, _, _} -> fun_name in ignored end)
    |> Enum.reduce([], fn invalid_call, issues ->
      {{:., _, [{:__aliases__, meta, module}, fun_name]}, _, _} = invalid_call

      found_config =
        Enum.find(module_configs, fn {mod, fun_list, _issue_message} ->
          mod == module and (fun_list in [:all, nil] or fun_name in fun_list)
        end)

      case found_config do
        {_, _fun_list, issue_message} ->
          trigger =
            invalid_call
            |> Macro.to_string()
            |> String.split("(")
            |> List.first()

          [issue_for(format_issue_fun, issue_meta, meta, trigger, module, issue_message) | issues]

        nil ->
          issues
      end
    end)
  end

  defp issue_for(format_issue_fun, issue_meta, meta, trigger, checked_module, message)
       when is_list(checked_module) do
    issue_for(format_issue_fun, issue_meta, meta, trigger, Module.concat(checked_module), message)
  end

  defp issue_for(format_issue_fun, issue_meta, meta, trigger, checked_module, message) do
    module_name = Credo.Code.Name.full(checked_module)

    format_issue_fun.(
      issue_meta,
      message: message || "There should be no unused return values for `#{module_name}` functions.",
      trigger: trigger,
      line_no: meta[:line],
      column: meta[:column]
    )
  end
end
