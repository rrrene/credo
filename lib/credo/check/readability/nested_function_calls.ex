defmodule Credo.Check.Readability.NestedFunctionCalls do
  use Credo.Check,
    id: "EX3012",
    tags: [:controversial],
    param_defaults: [min_pipeline_length: 2],
    explanations: [
      check: """
      A function call should not be nested inside another function call.

      So while this is fine:

          Enum.shuffle([1,2,3])

      The code in this example ...

          Enum.shuffle(Enum.uniq([1,2,3,3]))

      ... should be refactored to look like this:

          [1,2,3,3]
          |> Enum.uniq()
          |> Enum.shuffle()

      Nested function calls make the code harder to read. Instead, break the
      function calls out into a pipeline.

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """,
      params: [
        min_pipeline_length: "Set a minimum pipeline length"
      ]
    ]

  alias Credo.Check.PipeHelpers
  alias Credo.Code.Name

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    min_pipeline_length = Params.get(params, :min_pipeline_length, __MODULE__)

    {_min_pipeline_length, issues} =
      Credo.Code.prewalk(
        source_file,
        &traverse(&1, &2, issue_meta),
        {min_pipeline_length, []}
      )

    issues
  end

  # A call in a pipeline
  defp traverse({:|>, _meta, [pipe_input, {{:., _meta2, _fun}, _meta3, args}]}, accumulator, _issue_meta) do
    {[pipe_input, args], accumulator}
  end

  # A fully qualified call with no arguments
  defp traverse({{:., _meta, _call}, _meta2, []} = ast, accumulator, _issue_meta) do
    {ast, accumulator}
  end

  # Any call
  defp traverse(
         {{_name, _loc, call}, meta, args} = ast,
         {min_pipeline_length, issues} = acc,
         issue_meta
       ) do
    if valid_chain_start?(ast) do
      {ast, acc}
    else
      case length_as_pipeline(args) + 1 do
        potential_pipeline_length when potential_pipeline_length >= min_pipeline_length ->
          new_issues = issues ++ [issue_for(issue_meta, meta[:line], Name.full(call))]
          {ast, {min_pipeline_length, new_issues}}

        _ ->
          {nil, acc}
      end
    end
  end

  # Another expression, we must no longer be in a pipeline
  defp traverse(ast, {min_pipeline_length, issues}, _issue_meta) do
    {ast, {min_pipeline_length, issues}}
  end

  # Call with function call for first argument
  defp length_as_pipeline([{_name, _meta, args} = call_ast | _]) do
    if valid_chain_start?(call_ast) do
      0
    else
      1 + length_as_pipeline(args)
    end
  end

  # Call where the first argument isn't another function call
  defp length_as_pipeline(_args) do
    0
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message: "Use a pipeline when there are nested function calls",
      trigger: trigger,
      line_no: line_no
    )
  end

  defp valid_chain_start?(ast) do
    PipeHelpers.valid_chain_start?(ast, [], [])
  end
end
