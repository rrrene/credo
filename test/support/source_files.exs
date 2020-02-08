defmodule Credo.Test.SourceFiles do
  alias Credo.Test.FilenameGenerator

  def to_source_file(source) do
    to_source_file(source, FilenameGenerator.next())
  end

  def to_source_file(source, filename) do
    case Credo.SourceFile.parse(source, filename) do
      %{status: :valid} = source_file ->
        source_file

      _ ->
        raise "Source could not be parsed!"
    end
  end

  def to_source_files(list) do
    Enum.map(list, &to_source_file/1)
  end
end
