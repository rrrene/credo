defmodule Credo.Check.Consistency.Collector do
  @moduledoc """
  `Collector` is a behavior for consistency check modules
  that run on all source files.
  """

  alias Credo.Issue
  alias Credo.SourceFile

  @doc """
  The first step of a `Collector` run is counting occurrences of matches
  (e.g. :with_space and :without_space for a space around operators check).

  This function produces a map of matches as keys and their frequencies
  as values (e.g. %{with_space: 50, without_space: 40}) for a single source
  file.

  The maps for individual source files are then merged, producing a map
  that reflects frequency trends for the whole codebase.
  """
  @callback collect_matches(source_file :: SourceFile.t, params :: Keyword.t)
    :: %{term => non_neg_integer}

  @doc """
  Once the most frequent match is identified, the `Collector` looks up
  source files that have other matches (e.g. both :with_space
  and :without_space or just :without_space when :with_space is the
  most frequent) and calls the `issue_formatter` on them (see below).

  `issue_formatter` functions may call `find_locations` to obtain
  additional metadata for each occurrence of a match in a given file.
  """
  @callback find_locations(match :: term, source_file :: SourceFile.t)
    :: list(term)

  @optional_callbacks find_locations: 2

  @doc """
  An issue formatter produces a list of `Credo.Issue` structs
  from expected match and a tuple of {[other_matches], source_file, params}
  (the latter two are required to build an IssueMeta).
  """
  @type issue_formatter ::
    (term, {nonempty_list(term), SourceFile.t, Keyword.t} -> [Issue.t])

  defmacro __using__(_opts) do
    quote do
      @behaviour Credo.Check.Consistency.Collector

      alias Credo.Issue
      alias Credo.SourceFile
      alias Credo.Execution.Issues
      alias Credo.Check.Consistency.Collector

      @spec find_issues(
        [SourceFile.t], Keyword.t, Collector.issue_formatter) :: [Issue.t]
      def find_issues(source_files, params, issue_formatter) when is_list(source_files) and is_function(issue_formatter) do
        Collector.issues(source_files, __MODULE__, params, issue_formatter)
      end

      @spec insert_issue(Issue.t, Credo.Execution.t) :: term
      def insert_issue(%Issue{filename: filename} = issue, exec) do
        Issues.append(exec, %SourceFile{filename: filename}, issue)
      end
    end
  end

  def issues(source_files, collector, params, issue_formatter) do
    frequencies_per_file =
      Enum.map(source_files, fn(file) ->
        {file, collector.collect_matches(file, params)}
      end)

    frequencies = total_frequencies(frequencies_per_file)

    if map_size(frequencies) > 0 do
      {most_frequent, _frequency} =
        Enum.max_by(frequencies, &elem(&1, 1))

      frequencies_per_file
      |> issues_per_file(most_frequent, params)
      |> Enum.flat_map(&issue_formatter.(most_frequent, &1))
    else
      []
    end
  end

  defp issues_per_file(frequencies_per_file, most_frequent, params) do
    Enum.reduce(frequencies_per_file, [], fn({file, frequencies}, acc) ->
      invalid_values = Map.keys(frequencies) -- [most_frequent]

      if invalid_values != [] do
        [{invalid_values, file, params} | acc]
      else
        acc
      end
    end)
  end

  defp total_frequencies(frequencies_per_file) do
    Enum.reduce(frequencies_per_file, %{}, fn({_, frequencies}, stats) ->
      Map.merge(stats, frequencies, fn(_k, f1, f2) -> f1 + f2 end)
    end)
  end
end
