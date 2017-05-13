defmodule Credo.SourceFile do
  defstruct filename: nil,
            valid?:   nil

  @type t :: module

  alias Credo.Service.SourceFileAST
  alias Credo.Service.SourceFileLines
  alias Credo.Service.SourceFileSource

  def parse(source, filename) do
    filename = Path.relative_to_cwd(filename)
    lines = Credo.Code.to_lines(source)
    {valid, ast} =
      case Credo.Code.ast(source) do
        {:ok, ast} ->
          {true, ast}
        {:error, _errors} ->
          {false, []}
      end

    SourceFileAST.put(filename, ast)
    SourceFileLines.put(filename, lines)
    SourceFileSource.put(filename, source)

    %Credo.SourceFile{
      filename: filename,
      valid?:   valid
    }
  end

  def ast(%__MODULE__{filename: filename}) do
    case SourceFileAST.get(filename) do
      {:ok, ast} ->
        ast
      _ ->
        raise "Could not get source from ETS: #{filename}"
    end
  end

  def lines(%__MODULE__{filename: filename}) do
    case SourceFileLines.get(filename) do
      {:ok, lines} ->
        lines
      _ ->
        raise "Could not get source from ETS: #{filename}"
    end
  end

  def source(%__MODULE__{filename: filename}) do
    case SourceFileSource.get(filename) do
      {:ok, source} ->
        source
      _ ->
        raise "Could not get source from ETS: #{filename}"
    end
  end

  @doc """
  Returns the line at the given +line_no+.

  NOTE: +line_no+ is a 1-based index.
  """
  def line_at(%__MODULE__{} = source_file, line_no) do
    source_file
    |> lines()
    |> Enum.find_value(&find_line_at(&1, line_no))
  end

  defp find_line_at({line_no, text}, line_no), do: text
  defp find_line_at(_, _), do: nil

  @doc """
  Returns the snippet at the given +line_no+ between +column1+ and +column2+.

  NOTE: +line_no+ is a 1-based index.
  """
  def line_at(%__MODULE__{} = source_file, line_no, column1, column2) do
    source_file
    |> line_at(line_no)
    |> String.slice(column1 - 1, column2 - column1)
  end

  @doc """
  Returns the column of the given +trigger+ inside the given line.

  NOTE: Both +line_no+ and the returned index are 1-based.
  """
  def column(%__MODULE__{} = source_file, line_no, trigger) when is_binary(trigger) or is_atom(trigger) do
    line = line_at(source_file, line_no)
    regexed =
      trigger
      |> to_string
      |> Regex.escape

    case Regex.run(~r/\b#{regexed}\b/, line, return: :index) do
      nil ->
        nil
      result ->
        {col, _} = List.first(result)
        col + 1
    end
  end
  def column(_, _, _), do: nil

  defimpl Inspect, for: __MODULE__ do
    def inspect(source_file, _opts) do
      "%SourceFile<#{source_file.filename}>"
    end
  end
end
