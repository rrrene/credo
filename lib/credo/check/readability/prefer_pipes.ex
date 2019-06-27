defmodule Credo.Check.Readability.PreferPipes do
  @moduledoc false

  @checkdoc """
  Pipes (`|>`) should be preferred when performing nested function calls.

  So while this is fine:
      foo(bar)
  The code in this example ...
      foo(bar(baz))
  ... should be refactored to look like this:
      foo
      |> bar()
      |> baz()
  Nesting function calls makes it harder to change the inner values, and harder to read.
  Instead, move the nested calls to successive pipes.
  """
  @explanation [check: @checkdoc]

  @special_cases [
    :%,
    :%{},
    :..,
    :<<>>,
    :@,
    :__aliases__,
    :__block__,
    :unquote,
    :{},
    :&,
    :<>,
    :++,
    :--,
    :&&,
    :||,
    :|>,
    :-,
    :=,
    :|,
    :when,
    :and,
    :for,
    :with,
    :<-
  ]

  use Credo.Check, base_priority: :high

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    except = @special_cases ++ Keyword.get(params, :except, [])

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta, except))
  end

  defp traverse({outer, _, [{inner, _, [_ | _]} | [[{:do, _} | _]]]} = ast, issues, _, _)
       when is_atom(outer) and is_atom(inner) do
    {ast, issues}
  end

  defp traverse(
         {outer, meta, [{inner, _, [_ | _]} = inner_ast | _]} = ast,
         issues,
         issue_meta,
         except
       ) do
    cond do
      inner in except and outer in except ->
        {ast, issues}

      is_atom(inner) and valid_function_arg?(inner_ast, except) ->
        {ast, issues}

      outer in except ->
        {ast, issues}

      is_atom(inner) and is_atom(outer) ->
        {
          ast,
          issues ++ [issue_for(issue_meta, meta[:line], "prefer_pipes")]
        }

      true ->
        {ast, issues}
    end
  end

  defp traverse(ast, issues, _issue_meta, _) do
    {ast, issues}
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message: "Prefer pipes for nested function calls",
      trigger: trigger,
      line_no: line_no
    )
  end

  for atom <- @special_cases do
    defp valid_function_arg?(
           {unquote(atom), _meta, _arguments},
           _excluded_functions
         ) do
      true
    end
  end

  # anonymous function
  defp valid_function_arg?(
         {:fn, _, [{:->, _, [_args, _body]}]},
         _excluded_functions
       ) do
    true
  end

  # function_call()
  defp valid_function_arg?(
         {atom, _, []},
         _excluded_functions
       )
       when is_atom(atom) do
    true
  end

  # function_call(with, args) and sigils
  defp valid_function_arg?(
         {atom, _, arguments},
         _excluded_functions
       )
       when is_atom(atom) and is_list(arguments) do
    sigil?(atom)
  end

  # map[:access]
  defp valid_function_arg?(
         {{:., _, [Access, :get]}, _, _},
         _excluded_functions
       ) do
    true
  end

  # Module.function_call()
  defp valid_function_arg?(
         {{:., _, _}, _, []},
         _excluded_functions
       ),
       do: true

  # Elixir <= 1.8.0
  # '__#{val}__' are compiled to String.to_charlist("__#{val}__")
  # we want to consider these charlists a valid pipe chain start
  defp valid_function_arg?(
         {{:., _, [String, :to_charlist]}, _, [{:<<>>, _, _}]},
         _excluded_functions
       ),
       do: true

  # Elixir >= 1.8.0
  # '__#{val}__' are compiled to String.to_charlist("__#{val}__")
  # we want to consider these charlists a valid pipe chain start
  defp valid_function_arg?(
         {{:., _, [List, :to_charlist]}, _, [[_ | _]]},
         _excluded_functions
       ),
       do: true

  # Module.function_call(with, parameters)
  defp valid_function_arg?(
         {{:., _, _}, _, _},
         _excluded_functions
       ) do
    false
  end

  defp valid_function_arg?(_, _excluded_functions), do: true

  defp sigil?(atom) do
    atom
    |> to_string
    |> String.match?(~r/^sigil_[a-zA-Z]$/)
  end
end
