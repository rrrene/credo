defmodule Credo.Code do
  alias Credo.SourceFile

  defmodule ParserError do
    @explanation ""
    use Credo.Check, category: :error
  end

  def traverse(ast_or_source_file, fun, accumulator \\ [])
  def traverse(%SourceFile{ast: source_ast}, fun, accumulator) do
    traverse(source_ast, fun, accumulator)
  end
  def traverse(source_ast, fun, accumulator) do
    {_, accumulated} = Macro.prewalk(source_ast, accumulator, fun)
    accumulated
  end

  def ast(%SourceFile{source: source, filename: filename}) do
    ast(source, filename)
  end
  def ast(source, filename \\ "nofilename") do
    case Code.string_to_quoted(source, line: 1) do
      {:ok, value} -> {:ok, value}
      {:error, error} -> {:error, [issue_for(error, filename)]}
    end
  end

  def to_lines(source) do
    source
    |> String.split("\n")
    |> Enum.with_index
    |> Enum.map(fn {line, i} -> {i + 1, line} end)
  end

  defp issue_for({line_no, error_message, _}, filename) do
    %Credo.Issue{
      check:    ParserError,
      category: :error,
      filename: filename,
      message:  error_message,
      line_no:  line_no
    }
  end

end
