defmodule Credo.Code do
  @moduledoc """
  `Credo.Code` contains a lot of utility or helper functions that deal with the
  analysis of - you guessed it - code.

  Whenever a function serves a general purpose in this area, e.g. getting the
  value of a module attribute inside a given module, we want to extract that
  function and put it in the `Credo.Code` namespace, so others can utilize them
  without reinventing the wheel.

  The most often utilized functions are conveniently imported to
  `Credo.Check.CodeHelper`.
  """

  alias Credo.SourceFile

  defmodule ParserError do
    @moduledoc """
    This is an internal `Issue` raised by Credo when it finds itself unable to
    parse the source code in a file.
    """
  end

  @doc """
  Prewalks a given SourceFile's AST or a given AST.

  Technically this is just a wrapper around `Macro.prewalk/3`.
  """
  def prewalk(ast_or_source_file, fun, accumulator \\ [])
  def prewalk(%SourceFile{} = source_file, fun, accumulator) do
    source_file
    |> SourceFile.ast
    |> prewalk(fun, accumulator)
  end
  def prewalk(source_ast, fun, accumulator) do
    {_, accumulated} = Macro.prewalk(source_ast, accumulator, fun)

    accumulated
  end

  @doc """
  Postwalks a given SourceFile's AST or a given AST.

  Technically this is just a wrapper around `Macro.postwalk/3`.
  """
  def postwalk(ast_or_source_file, fun, accumulator \\ [])
  def postwalk(%SourceFile{} = source_file, fun, accumulator) do
    source_file
    |> SourceFile.ast
    |> postwalk(fun, accumulator)
  end
  def postwalk(source_ast, fun, accumulator) do
    {_, accumulated} = Macro.postwalk(source_ast, accumulator, fun)

    accumulated
  end

  @doc """
  Takes a SourceFile or String and returns an AST.
  """
  def ast(%SourceFile{filename: filename} = source_file) do
    source_file
    |> SourceFile.source
    |> ast(filename)
  end
  def ast(source, filename \\ "nofilename") when is_binary(source) do
    try do
      case Code.string_to_quoted(source, line: 1) do
        {:ok, value} ->
          {:ok, value}
        {:error, error} ->
          {:error, [issue_for(error, filename)]}
      end
    rescue
      e in UnicodeConversionError ->
        {:error, [issue_for({1, e.message, nil}, filename)]}
    end
  end

  @doc """
  Converts a String into a List of tuples of `{line_no, line}`.
  """
  def to_lines(%SourceFile{} = source_file) do
    source_file
    |> SourceFile.source
    |> to_lines()
  end
  def to_lines(source) when is_binary(source) do
    source
    |> String.split("\n")
    |> Enum.with_index
    |> Enum.map(fn({line, i}) -> {i + 1, line} end)
  end

  @doc """
  Converts a String into a List of tokens using the `:elixir_tokenizer`.
  """
  def to_tokens(%SourceFile{} = source_file) do
    source_file
    |> SourceFile.source
    |> to_tokens()
  end
  def to_tokens(source) when is_binary(source) do
    {_, _, _, tokens} =
      source
      |> Credo.Backports.String.to_charlist
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
