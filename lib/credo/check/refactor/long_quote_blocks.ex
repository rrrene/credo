defmodule Credo.Check.Refactor.LongQuoteBlocks do
  @moduledoc """
  Long `quote` blocks are generally an indication that too much is done inside
  them.

  Let's look at why this is problematic:

      defmodule MetaCommand do
        def __using__(opts \\\\ []) do
          modes = opts[:modes]
          command_name = opts[:command_name]

          quote do
            def run(filename) do
              contents =
                if File.exists?(filename) do
                  {:ok, file} = File.open(filename, unquote(modes))
                  {:ok, contents} = IO.read(file, :line)
                  File.close(file)
                  contents
                else
                  ""
                end

              case contents do
                "" ->
                  # ...
                unquote(command_name) <> rest ->
                  # ...
              end
            end

            # ...
          end
        end
      end

  A cleaner solution would be to call "regular" functions outside the
  `quote` block to perform the actual work.

      defmodule MyMetaCommand do
        def __using__(opts \\\\ []) do
          modes = opts[:modes]
          command_name = opts[:command_name]

          quote do
            def run(filename) do
              MyMetaCommand.run_on_file(filename, unquote(modes), unquote(command_name))
            end

            # ...
          end
        end

        def run_on_file(filename, modes, command_name) do
          contents =
            # actual implementation
        end
      end

  This way it is easier to reason about what is actually happening. And to debug
  it.
  """

  @explanation [
    check: @moduledoc,
    params: [
      max_line_count: "The maximum number of lines a quote block should be allowed to have.",
    ]
  ]
  @default_params [max_line_count: 150]

  use Credo.Check, base_priority: :high

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    max_line_count = Params.get(params, :max_line_count, @default_params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta, max_line_count))
  end

  defp traverse({:quote, meta, arguments} = ast, issues, issue_meta, max_line_count) do
    max_line_no = Credo.Code.prewalk(arguments, &find_max_line_no(&1, &2), 0)
    line_count = max_line_no - meta[:line]

    issue =
      if line_count > max_line_count do
        issue_for(issue_meta, meta[:line])
      end

    {ast, issues ++ List.wrap(issue)}
  end
  defp traverse(ast, issues, _issue_meta, _max_line_count) do
    {ast, issues}
  end

  defp find_max_line_no({_, meta, _} = ast, max_line_no) do
    line_no = meta[:line] || 0

    if line_no > max_line_no do
      {ast, line_no}
    else
      {ast, max_line_no}
    end
  end
  defp find_max_line_no(ast, max_line_no) do
    {ast, max_line_no}
  end

  defp issue_for(issue_meta, line_no) do
    format_issue issue_meta,
      message: "Avoid long quote blocks.",
      trigger: "quote",
      line_no: line_no
  end
end
