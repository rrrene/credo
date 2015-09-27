defmodule Credo.SourceFile do
  defstruct path:             nil,
            source:           nil,
            lines:            nil,
            ast:              nil,
            valid?:           nil,
            errors:           []

  def parse(source, path) do
    %Credo.SourceFile{
      path:             path,
      source:           source,
      lines:            source |> Credo.Code.to_lines,
    } |> with_ast
  end

  def line_at(source_file, line_no) do
    Enum.find_value(source_file.lines, fn {_line_no, line} ->
      if _line_no == line_no, do: line
    end)
  end

  def column(source_file, line_no, trigger) do
    line = line_at(source_file, line_no)
    {col, _} = Regex.run(~r/#{trigger}/, line, return: :index) |> List.first
    col
  end

  defp with_ast(%Credo.SourceFile{source: source} = source_file) do
    case Credo.Code.ast(source) do
      {:ok, ast} ->
        %Credo.SourceFile{source_file | valid?: true, ast: ast}
      {:error, errors} ->
        %Credo.SourceFile{source_file | valid?: false, ast: [], errors: errors}
    end
  end
end
