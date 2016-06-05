defmodule Credo.Sources do
  alias Credo.SourceFile

  @default_sources_glob ~w(** *.{ex,exs})
  @stdin_filename "stdin"

  @doc """
  Finds sources for a given Config, List or String.

  iex> Sources.find(%Credo.Config{files: %{excluded: [], included: ["*.ex"]}})

  iex> Sources.find(["lib/credo_*.ex", "lib/credo/*.ex"])

  iex> Sources.find("*.ex")

  """
  def find(%Credo.Config{files: %{excluded: [], included: [filename]}, read_from_stdin: true}) do
    filename |> source_file_from_stdin() |> List.wrap
  end
  def find(%Credo.Config{read_from_stdin: true}) do
    @stdin_filename |> source_file_from_stdin() |> List.wrap
  end
  def find(%Credo.Config{files: files}) do
    files.included
    |> Enum.flat_map(&find/1)
    |> exclude(files.excluded)
    |> to_source_files
  end
  def find(paths) when is_list(paths) do
    paths
    |> Enum.flat_map(&find/1)
  end
  def find(path) when is_binary(path) do
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
    |> SourceFile.parse(filename)
  end

  defp matches?(file, patterns) when is_list(patterns) do
    patterns
    |> Enum.any?(&matches?(file, &1))
  end
  defp matches?(file, string) when is_binary(string) do
    string
    |> find
    |> Enum.member?(file)
  end
  defp matches?(file, regex) do
    String.match?(file, regex)
  end

  defp source_file_from_stdin(filename) do
    read_from_stdin!
    |> SourceFile.parse(filename)
  end

  defp read_from_stdin! do
    {:ok, source} = read_from_stdin
    source
  end

  defp read_from_stdin(source \\ "") do
    case IO.read(:stdio, :line) do
      {:error, reason} -> {:error, reason}
      :eof             -> {:ok, source}
      data             -> source = source <> data
        read_from_stdin(source)
    end
  end
end
