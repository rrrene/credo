defmodule Credo.Sources do
  @moduledoc """
  This module is used to find and read all source files for analysis.
  """

  alias Credo.Execution
  alias Credo.SourceFile
  alias Credo.Sources.FileTree

  @default_sources_glob ~w(** *.{ex,exs})
  @stdin_filename "stdin"

  @doc false
  def filename_matches?(filename, patterns) do
    patterns
    |> List.wrap()
    |> Enum.any?(&match_filename_pattern(filename, &1))
  end

  defp match_filename_pattern(filename, pattern) when is_binary(pattern) do
    if String.contains?(pattern, "*") do
      matches_glob_naively?(filename, pattern)
    else
      String.starts_with?(filename, pattern)
    end
  end

  defp match_filename_pattern(filename, %Regex{} = pattern), do: String.match?(filename, pattern)

  defp match_filename_pattern(_, pattern),
    do: raise("Expected String or Regex, got: #{inspect(pattern)}")

  # naively converts glob pattern to regex
  # does not account for brace or tilde expansion or command substitution
  # or anything other than * and **
  defp matches_glob_naively?(filename, pattern) do
    string =
      pattern
      |> String.replace("**/*", ".+")
      |> String.replace("/", "\\/")
      |> String.replace("**", ".+")
      |> String.replace("*", "[^\/]+")

    case Regex.compile("#{string}$") do
      {:ok, regex} -> String.match?(filename, regex)
      _ -> raise "Compiling glob pattern to regex failed: #{inspect(pattern)}"
    end
  end

  @doc """
  Finds sources for a given `Credo.Execution`.

  Through the `files` key, configs may contain a list of `included` and `excluded`
  patterns. For `included`, patterns can be file paths, directory paths and globs.
  For `excluded`, patterns can also be specified as regular expressions.

      iex> Sources.find(%Credo.Execution{config: %{files: %{excluded: ["not_me.ex"], included: ["*.ex"]}}})

      iex> Sources.find(%Credo.Execution{config: %{files: %{excluded: [~r/messy/], included: ["lib/mix", "root.ex"]}}})
  """
  def find(exec)

  def find(%Execution{config: %{read_from_stdin: true, files: %{included: [filename]}}}) do
    filename
    |> source_file_from_stdin()
    |> List.wrap()
  end

  def find(%Execution{config: %{read_from_stdin: true}}) do
    @stdin_filename
    |> source_file_from_stdin()
    |> List.wrap()
  end

  def find(%Execution{config: %{files: files}} = exec) do
    parse_timeout =
      case Execution.get_config(exec, :parse_timeout) do
        nil -> :infinity
        value -> value
      end

    working_dir = Execution.working_dir(exec)

    included_patterns = convert_globs_to_local_paths(working_dir, files.included)
    excluded_patterns = convert_globs_to_local_paths(working_dir, files.excluded)

    MapSet.new()
    |> include(included_patterns, :disk)
    |> exclude(excluded_patterns, :disk)
    |> Enum.sort()
    |> Enum.take(max_file_count())
    |> read_files(parse_timeout)
  end

  def find(nil) do
    []
  end

  def find(paths) when is_list(paths) do
    Enum.flat_map(paths, &find/1)
  end

  def find(path) when is_binary(path) do
    recurse_path(path, :disk)
  end

  @doc """
  Finds sources in a given `directory` using a list of `included` and `excluded`
  patterns. For `included`, patterns can be file paths, directory paths and globs.
  For `excluded`, patterns can also be specified as regular expressions.

      iex> Sources.find_in_dir("/home/rrrene/elixir", ["*.ex"], ["not_me.ex"])

      iex> Sources.find_in_dir("/home/rrrene/elixir", ["*.ex"], [~r/messy/])
  """
  def find_in_dir(working_dir, included, excluded)

  def find_in_dir(working_dir, [], excluded),
    do: find_in_dir(working_dir, [Path.join(@default_sources_glob)], excluded)

  def find_in_dir(working_dir, included, excluded) do
    do_find_in_dir(working_dir, included, excluded, :disk)
  end

  @doc false
  # Filters the given expanded `paths` to just the subset the `included` and `excluded` patterns allow.
  #
  # This matches what `find_in_dir/3` would return, but it avoids hitting the filesystem.
  # It's used to determine which of the already loaded source files a check's `files` param filters it to.
  def find_in_paths(paths, working_dir, included, excluded)

  def find_in_paths(paths, working_dir, [], excluded),
    do: find_in_paths(paths, working_dir, [Path.join(@default_sources_glob)], excluded)

  def find_in_paths(paths, working_dir, included, excluded) do
    do_find_in_dir(working_dir, included, excluded, FileTree.new(paths))
  end

  defp do_find_in_dir(working_dir, included, excluded, fs) do
    included_patterns = convert_globs_to_local_paths(working_dir, included)
    excluded_patterns = convert_globs_to_local_paths(working_dir, excluded)

    MapSet.new()
    |> include(included_patterns, fs)
    |> exclude(excluded_patterns, fs)
    |> Enum.sort()
    |> Enum.take(max_file_count())
  end

  defp convert_globs_to_local_paths(working_dir, patterns) do
    patterns
    |> List.wrap()
    |> Enum.map(fn
      pattern when is_binary(pattern) -> Path.expand(pattern, working_dir)
      pattern -> pattern
    end)
  end

  defp max_file_count do
    max_files = System.get_env("MAX_FILES")

    if max_files do
      String.to_integer(max_files)
    else
      1_000_000
    end
  end

  defp include(files, [], _fs), do: files

  defp include(files, [path | remaining_paths], fs) do
    include_paths =
      path
      |> recurse_path(fs)
      |> Enum.into(MapSet.new())

    files
    |> MapSet.union(include_paths)
    |> include(remaining_paths, fs)
  end

  defp exclude(files, [], _fs), do: files

  defp exclude(files, [pattern | remaining_patterns], fs) when is_list(files) do
    files
    |> Enum.into(MapSet.new())
    |> exclude([pattern | remaining_patterns], fs)
  end

  defp exclude(files, [pattern | remaining_patterns], fs) when is_binary(pattern) do
    exclude_paths =
      pattern
      |> recurse_path(fs)
      |> Enum.into(MapSet.new())

    files
    |> MapSet.difference(exclude_paths)
    |> exclude(remaining_patterns, fs)
  end

  defp exclude(files, [pattern | remaining_patterns], fs) do
    files
    |> Enum.reject(&String.match?(&1, pattern))
    |> exclude(remaining_patterns, fs)
  end

  defp recurse_path(path, fs) do
    paths =
      cond do
        non_wildcard_elixir_file_path?(path) ->
          [path]

        regular?(fs, path) ->
          [path]

        dir?(fs, path) ->
          wildcard(fs, Path.join([path | @default_sources_glob]))

        true ->
          case wildcard(fs, path) do
            # avoid infinite loop caused by broken symlinks
            [^path] -> [path]
            paths -> Enum.flat_map(paths, &recurse_path(&1, fs))
          end
      end

    Enum.map(paths, &Path.expand/1)
  end

  defp regular?(:disk, path), do: File.regular?(path)
  defp regular?(fs, path), do: FileTree.regular?(fs, path)

  defp dir?(:disk, path), do: File.dir?(path)
  defp dir?(fs, path), do: FileTree.dir?(fs, path)

  defp wildcard(:disk, glob), do: Path.wildcard(glob)
  defp wildcard(fs, glob), do: FileTree.wildcard(fs, glob)

  defp non_wildcard_elixir_file_path?(path) do
    wildcard_characters = ["*", "{", "}", "?", "[", "]"]
    String.ends_with?(path, [".ex", ".exs"]) and not String.contains?(path, wildcard_characters)
  end

  defp read_files(filenames, parse_timeout) do
    filenames
    |> Task.async_stream(&to_source_file/1, timeout: parse_timeout, on_timeout: :kill_task)
    |> Stream.zip(filenames)
    |> Enum.map(fn
      {{:exit, :timeout}, filename} -> SourceFile.timed_out(filename)
      {{:ok, value}, _} -> value
    end)
  end

  defp to_source_file(filename) do
    filename
    |> File.read!()
    |> SourceFile.parse(filename)
  end

  defp source_file_from_stdin(filename) do
    SourceFile.parse(read_from_stdin!(), filename)
  end

  defp read_from_stdin! do
    {:ok, source} = read_from_stdin()
    source
  end

  defp read_from_stdin(source \\ "") do
    case IO.read(:stdio, :line) do
      {:error, reason} ->
        {:error, reason}

      :eof ->
        {:ok, source}

      data ->
        source = source <> data
        read_from_stdin(source)
    end
  end
end
