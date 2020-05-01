defmodule Credo.Check.Refactor.LongQuoteBlocks do
  use Credo.Check,
    base_priority: :high,
    param_defaults: [max_line_count: 150, ignore_comments: false],
    explanations: [
      check: """
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
      """,
      params: [
        max_line_count: "The maximum number of lines a quote block should be allowed to have.",
        ignore_comments: "Ignores comments when counting the lines of a `quote` block."
      ]
    ]

  alias Credo.IssueMeta

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)
    max_line_count = Params.get(params, :max_line_count, __MODULE__)
    ignore_comments = Params.get(params, :ignore_comments, __MODULE__)

    Credo.Code.prewalk(
      source_file,
      &traverse(&1, &2, issue_meta, max_line_count, ignore_comments)
    )
  end

  # TODO: consider for experimental check front-loader (ast)
  defp traverse(
         {:quote, meta, arguments} = ast,
         issues,
         issue_meta,
         max_line_count,
         ignore_comments
       ) do
    max_line_no = Credo.Code.prewalk(arguments, &find_max_line_no(&1, &2), 0)
    line_count = max_line_no - meta[:line]

    issue =
      if line_count > max_line_count do
        source_file = IssueMeta.source_file(issue_meta)

        lines =
          source_file
          |> Credo.Code.to_lines()
          |> Enum.slice(meta[:line] - 1, line_count)

        lines =
          if ignore_comments do
            Enum.reject(lines, fn {_line_no, line} ->
              Regex.run(~r/^\s*#/, line)
            end)
          else
            lines
          end

        if Enum.count(lines) > max_line_count do
          issue_for(issue_meta, meta[:line])
        end
      end

    {ast, issues ++ List.wrap(issue)}
  end

  defp traverse(ast, issues, _issue_meta, _max_line_count, _ignore_comments) do
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
    format_issue(
      issue_meta,
      message: "Avoid long quote blocks.",
      trigger: "quote",
      line_no: line_no
    )
  end
end
