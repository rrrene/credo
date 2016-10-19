defmodule Credo.Sources do
  alias Credo.SourceFile

  @default_sources_glob ~w(** *.{ex,exs})
  @stdin_filename "stdin"

  @doc """
  Finds sources for a given `Credo.Config`.

  Through the `files` key, configs may contain a list of `included` and `excluded`
  patterns. For `included`, patterns can be file paths, directory paths and globs.
  For `excluded`, patterns can also be specified as regular expressions.

  iex> Sources.find(%Credo.Config{files: %{excluded: ["not_me.ex"], included: ["*.ex"]}})

  iex> Sources.find(%Credo.Config{files: %{excluded: [/messy/], included: ["lib/mix", "root.ex"]}})

  """
  def find(%Credo.Config{files: %{included: [filename]}, read_from_stdin: true}) do
    filename |> source_file_from_stdin() |> List.wrap
  end
  def find(%Credo.Config{read_from_stdin: true}) do
    @stdin_filename |> source_file_from_stdin() |> List.wrap
  end
  def find(%Credo.Config{files: files}) do
    MapSet.new
    |> include(files.included)
    |> exclude(files.excluded)
    |> Enum.map(&to_source_file/1)
  end
  def find(paths) when is_list(paths) do
    paths
    |> Enum.flat_map(&find/1)
  end
  def find(path) when is_binary(path) do
    path |> recurse_path()
  end

  defp include(files, []), do: files
  defp include(files, [path | remaining_paths]) do
    include_paths = recurse_path(path) |> Enum.into(MapSet.new)

    files
    |> MapSet.union(include_paths)
    |> include(remaining_paths)
  end

  defp exclude(files, []), do: files
  defp exclude(files, [pattern | remaining_patterns]) when is_list(files) do
    files
    |> Enum.into(MapSet.new)
    |> exclude([pattern | remaining_patterns])
  end
  defp exclude(files, [pattern | remaining_patterns]) when is_binary(pattern) do
    exclude_paths = recurse_path(pattern) |> Enum.into(MapSet.new)

    files
    |> MapSet.difference(exclude_paths)
    |> exclude(remaining_patterns)
  end
  defp exclude(files, [pattern | remaining_patterns]) do
    files
    |> Enum.reject(&(String.match?(&1, pattern)))
    |> exclude(remaining_patterns)
  end

  defp recurse_path(path) do
    paths =
      cond do
        File.regular?(path) ->
          [path]
        File.dir?(path) ->
          [path | @default_sources_glob]
          |> Path.join
          |> Path.wildcard
        true ->
          path
          |> Path.wildcard
          |> Enum.flat_map(&recurse_path/1)
      end

    paths |> Enum.map(&Path.expand/1)
  end

  defp to_source_file(filename) do
    filename
    |> File.read!
    |> SourceFile.parse(filename)
  end

  defp source_file_from_stdin(filename) do
    read_from_stdin!()
    |> SourceFile.parse(filename)
  end

  defp read_from_stdin! do
    {:ok, source} = read_from_stdin()
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
