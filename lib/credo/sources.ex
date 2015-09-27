defmodule Credo.Sources do
  @always_excluded_dirs ~w(_build/ deps/ tmp/)

  def find(%Credo.Config{files: files}) do
    files.included
    |> Enum.map(&find/1)
    |> List.flatten
    |> exclude(files.excluded)
    |> to_source_files
  end

  def find(path) do
    path
    |> to_glob
    |> Path.wildcard
    |> Enum.reject( &String.starts_with?(&1, @always_excluded_dirs) )
  end

  def exclude(files, patterns \\ []) do
    Enum.reject(files, &matches?(&1, patterns))
  end

  defp to_glob(path) do
    if File.dir?(path) do
      [path, "**", "*.{ex,exs}"]
      |> Path.join
    else
      path
    end
  end

  def to_source_files(files) do
    Enum.map(files, &to_source_file(&1))
  end

  defp to_source_file(filename) do
    filename
    |> File.read!
    |> Credo.SourceFile.parse(filename)
  end

  defp matches?(string, regexes) do
    Enum.any?(regexes, &Regex.match?(&1, string))
  end
end
