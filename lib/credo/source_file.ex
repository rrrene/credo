defmodule Credo.SourceFile do
  @moduledoc """
  `SourceFile` structs represent a source file in the codebase.
  """

  @type t :: %__MODULE__{
          filename: nil | String.t(),
          hash: String.t(),
          status: :valid | :invalid | :timed_out
        }

  alias Credo.Service.SourceFileAST
  alias Credo.Service.SourceFileLines
  alias Credo.Service.SourceFileSource

  defstruct filename: nil,
            hash: nil,
            status: nil

  defimpl Inspect, for: __MODULE__ do
    def inspect(source_file, _opts) do
      "%SourceFile<#{source_file.filename}>"
    end
  end

  @doc """
  Returns a `SourceFile` struct for the given `source` code and `filename`.
  """
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

    hash =
      :sha256
      |> :crypto.hash(source)
      |> Base.encode16()

    source_file = %Credo.SourceFile{
      filename: filename,
      hash: hash,
      status: if(valid, do: :valid, else: :invalid)
    }

    SourceFileAST.put(source_file, ast)
    SourceFileLines.put(source_file, lines)
    SourceFileSource.put(source_file, source)

    source_file
  end

  @spec timed_out(String.t()) :: t
  def timed_out(filename) do
    filename = Path.relative_to_cwd(filename)

    %Credo.SourceFile{
      filename: filename,
      hash: "timed_out:#{filename}",
      status: :timed_out
    }
  end

  @doc "Returns the AST for the given `source_file`."
  def ast(source_file)

  def ast(%__MODULE__{} = source_file) do
    case SourceFileAST.get(source_file) do
      {:ok, ast} ->
        ast

      _ ->
        raise "Could not get source from ETS: #{source_file.filename}"
    end
  end

  @doc "Returns the lines of source code for the given `source_file`."
  def lines(source_file)

  def lines(%__MODULE__{} = source_file) do
    case SourceFileLines.get(source_file) do
      {:ok, lines} ->
        lines

      _ ->
        raise "Could not get source from ETS: #{source_file.filename}"
    end
  end

  @doc "Returns the source code for the given `source_file`."
  def source(source_file)

  def source(%__MODULE__{} = source_file) do
    case SourceFileSource.get(source_file) do
      {:ok, source} ->
        source

      _ ->
        raise "Could not get source from ETS: #{source_file.filename}"
    end
  end

  @doc "Returns the source code and filename for the given `source_file_or_source`."
  def source_and_filename(source_file_or_source, default_filename \\ "nofilename")

  def source_and_filename(%__MODULE__{filename: filename} = source_file, _default_filename) do
    {source(source_file), filename}
  end

  def source_and_filename(source, default_filename) when is_binary(source) do
    {source, default_filename}
  end

  @doc """
  Returns the line at the given `line_no`.

  NOTE: `line_no` is a 1-based index.
  """
  def line_at(%__MODULE__{} = source_file, line_no) do
    source_file
    |> lines()
    |> Enum.find_value(&find_line_at(&1, line_no))
  end

  defp find_line_at({line_no, text}, line_no), do: text
  defp find_line_at(_, _), do: nil

  @doc """
  Returns the snippet at the given `line_no` between `column1` and `column2`.

  NOTE: `line_no` is a 1-based index.
  """
  def line_at(%__MODULE__{} = source_file, line_no, column1, column2) do
    source_file
    |> line_at(line_no)
    |> String.slice(column1 - 1, column2 - column1)
  end

  @doc """
  Returns the column of the given `trigger` inside the given line.

  NOTE: Both `line_no` and the returned index are 1-based.
  """
  def column(source_file, line_no, trigger)

  def column(%__MODULE__{} = source_file, line_no, trigger)
      when is_binary(trigger) or is_atom(trigger) do
    line = line_at(source_file, line_no)

    regexed =
      trigger
      |> to_string
      |> Regex.escape()

    case Regex.run(~r/(\b|\(|\)|\,)(#{regexed})(\b|\(|\)|\,)/, line, return: :index) do
      nil ->
        nil

      [_, _, {regexed_col, _regexed_length}, _] ->
        regexed_col + 1
    end
  end

  def column(_, _, _), do: nil
end
