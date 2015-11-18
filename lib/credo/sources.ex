defmodule Credo.Sources do
  @default_sources_glob ~w(** *.{ex,exs})

  def find(%Credo.Config{files: files}) do
    files.included
    |> Enum.flat_map(&find/1)
    |> exclude(files.excluded)
    |> to_source_files
  end

  def find(path) do
    path
    |> to_glob
    |> Path.wildcard
  end

  def exclude(files, patterns \\ []) do
    Enum.reject(files, &matches?(&1, patterns))
  end

  defp to_glob(path) do
    if File.dir?(path) do
      [path | @default_sources_glob]
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

  defp matches?(file, exclude_patterns) when is_list(exclude_patterns) do
    exclude_patterns
    |> Enum.any?(&matches?(file, &1))
  end
  defp matches?(file, string) when is_binary(string) do
    find(string)
    |> Enum.member?(file)
  end
  defp matches?(file, regex) do
    String.match?(file, regex)
  end
end
