defmodule Credo.Check.Readability.NestedFunctionCalls do
  use Credo.Check,
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

  alias Credo.Code.Name

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    min_pipeline_length = Params.get(params, :min_pipeline_length, __MODULE__)

    {_continue, issues} =
      Credo.Code.prewalk(
        source_file,
        &traverse(&1, &2, issue_meta, min_pipeline_length),
        {true, []}
      )

    issues
  end

  # A call with no arguments
  defp traverse({{:., _loc, _call}, _meta, []} = ast, {_, issues}, _, min_pipeline_length) do
    {ast, {min_pipeline_length, issues}}
  end

  # A call with arguments
  defp traverse(
         {{:., _loc, call}, meta, args} = ast,
         {_, issues},
         issue_meta,
         min_pipeline_length
       ) do
    if valid_chain_start?(ast) do
      {ast, {min_pipeline_length, issues}}
    else
      case length_as_pipeline(args) + 1 do
        potential_pipeline_length when potential_pipeline_length >= min_pipeline_length ->
          {ast,
           {min_pipeline_length, issues ++ [issue_for(issue_meta, meta[:line], Name.full(call))]}}

        _ ->
          {ast, {min_pipeline_length, issues}}
      end
    end
  end

  # Another expression
  defp traverse(ast, {_, issues}, _issue_meta, min_pipeline_length) do
    {ast, {min_pipeline_length, issues}}
  end

  # Call with no arguments
  defp length_as_pipeline([{{:., _loc, _call}, _meta, []} | _]) do
    0
  end

  # Call with function call for first argument
  defp length_as_pipeline([{{:., _loc, _call}, _meta, args} = call_ast | _]) do
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

  # Taken from the Credo.Check.Refactor.PipeChainStart module, with modifications
  # map[:access]
  defp valid_chain_start?({{:., _, [Access, :get]}, _, _}), do: true

  # Module.function_call()
  defp valid_chain_start?({{:., _, _}, _, []}), do: true

  # Kernel.to_string is invoked for string interpolation e.g. "string #{variable}"
  defp valid_chain_start?({{:., _, [Kernel, :to_string]}, _, _}), do: true

  defp valid_chain_start?(_), do: false
end
