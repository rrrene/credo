defmodule Credo.SourceFile do
  defstruct filename: nil,
            source:   nil,
            lines:    nil,
            ast:      nil,
            valid?:   nil,
            issues:   [],
            lint_attributes: []

  @type t :: module

  def parse(source, filename) do
    source_file =
      %Credo.SourceFile{
        filename: Path.relative_to_cwd(filename),
        source:   source,
        lines:    Credo.Code.to_lines(source),
      }

    with_ast(source_file)
  end

  @doc """
  Returns the line at the given +line_no+.

  NOTE: +line_no+ is a 1-based index.
  """
  def line_at(source_file, line_no) do
    Enum.find_value(source_file.lines,
      fn
        {line_no2, text} when line_no == line_no2 -> text
        _ -> nil
      end
    )
  end

  @doc """
  Returns the snippet at the given +line_no+ between +column1+ and +column2+.

  NOTE: +line_no+ is a 1-based index.
  """
  def line_at(source_file, line_no, column1, column2) do
    source_file
    |> line_at(line_no)
    |> String.slice(column1 - 1, column2 - column1)
  end

  @doc """
  Returns the column of the given +trigger+ inside the given line.

  NOTE: Both +line_no+ and the returned index are 1-based.
  """
  def column(source_file, line_no, trigger) when is_binary(trigger) or is_atom(trigger) do
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

  defp with_ast(%Credo.SourceFile{} = source_file) do
    case Credo.Code.ast(source_file) do
      {:ok, ast} ->
        %Credo.SourceFile{source_file | valid?: true, ast: ast}
      {:error, errors} ->
        %Credo.SourceFile{source_file | valid?: false, ast: [], issues: errors}
    end
  end
end
