defmodule Credo.Code do
  @moduledoc """
  Credo.Code contains a lot of utility or helper functions that deal with the
  analysis if - you guessed it - Code.

  Whenever a function serves a general purpose in this area, e.g. getting the
  value of a module attribute inside a given module, we want to extract that
  function and put it here, so others can utilize them without reinventing
  the wheel.
  """

  alias Credo.SourceFile

  defmodule ParserError do
    @explanation []
    use Credo.Check, category: :error, base_priority: :normal
  end

  @doc """
  Traverses a given SourceFile's AST or a given AST.

  Technically this is just a wrapper around `Macro.prewalk/3`.
  """
  def traverse(ast_or_source_file, fun, accumulator \\ [])
  def traverse(%SourceFile{ast: source_ast}, fun, accumulator) do
    traverse(source_ast, fun, accumulator)
  end
  def traverse(source_ast, fun, accumulator) do
    {_, accumulated} = Macro.prewalk(source_ast, accumulator, fun)
    accumulated
  end

  @doc """
  Takes a SourceFile or String and returns an AST.
  """
  def ast(%SourceFile{source: source, filename: filename}) do
    ast(source, filename)
  end
  def ast(source, filename \\ "nofilename") do
    case Code.string_to_quoted(source, line: 1) do
      {:ok, value} -> {:ok, value}
      {:error, error} -> {:error, [issue_for(error, filename)]}
    end
  end

  @doc """
  Converts a String into a List of tuples of `{line_no, line}`.
  """
  def to_lines(source) do
    source
    |> String.split("\n")
    |> Enum.with_index
    |> Enum.map(fn({line, i}) -> {i + 1, line} end)
  end

  @doc """
  Converts a String into a List of tokens using the `:elixir_tokenizer`.
  """
  def to_tokens(source) do
    {_, _, _, tokens} =
      source
      |> String.to_char_list
      |> :elixir_tokenizer.tokenize(1, [])
    tokens
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
