defmodule Credo.Check.Refactor.PipeChainStart do
  use Credo.Check,
    id: "EX4023",
    tags: [:controversial],
    param_defaults: [
      excluded_argument_types: [],
      excluded_functions: []
    ],
    explanations: [
      check: """
      Pipes (`|>`) can become more readable by starting with a "raw" value.

      So while this is easily comprehendable:

          list
          |> Enum.take(5)
          |> Enum.shuffle
          |> pick_winner()

      This might be harder to read:

          Enum.take(list, 5)
          |> Enum.shuffle
          |> pick_winner()

      As always: This is just a suggestion. Check the configuration options for
      tweaking or disabling this check.
      """,
      params: [
        excluded_functions: "All functions listed will be ignored.",
        excluded_argument_types: "All pipes with argument types listed will be ignored."
      ]
    ]

  alias Credo.Check.PipeHelpers

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    excluded_functions = Params.get(params, :excluded_functions, __MODULE__)

    excluded_argument_types = Params.get(params, :excluded_argument_types, __MODULE__)

    Credo.Code.prewalk(
      source_file,
      &traverse(&1, &2, issue_meta, excluded_functions, excluded_argument_types)
    )
  end

  # TODO: consider for experimental check front-loader (ast)
  defp traverse(
         {:|>, _, [{:|>, _, _} | _]} = ast,
         issues,
         _issue_meta,
         _excluded_functions,
         _excluded_argument_types
       ) do
    {ast, issues}
  end

  defp traverse(
         {:|>, meta, [lhs | _rhs]} = ast,
         issues,
         issue_meta,
         excluded_functions,
         excluded_argument_types
       ) do
    if PipeHelpers.valid_chain_start?(lhs, excluded_functions, excluded_argument_types) do
      {ast, issues}
    else
      {ast, issues ++ [issue_for(issue_meta, meta[:line], "TODO")]}
    end
  end

  defp traverse(
         ast,
         issues,
         _issue_meta,
         _excluded_functions,
         _excluded_argument_types
       ) do
    {ast, issues}
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message: "Pipe chain should start with a raw value.",
      trigger: trigger,
      line_no: line_no
    )
  end
end
