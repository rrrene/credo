defmodule Credo.Check.Consistency.Collector do
  @moduledoc """
  `Collector` is a behavior for consistency check modules
  that run on all source files.
  """

  alias Credo.Issue
  alias Credo.SourceFile
  alias Credo.Execution.Issues

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

  `issue_formatter` functions may call `find_locations_not_matching`
  to obtain additional metadata for each occurrence of
  an unexpected match in a given file.
  """
  @callback find_locations_not_matching(
    expected :: term, source_file :: SourceFile.t) :: list(term)

  @optional_callbacks find_locations_not_matching: 2

  @doc """
  An issue formatter produces a list of `Credo.Issue` structs
  from an expected match, a source file with unexpected matches,
  and check params (the latter two are required to build an IssueMeta).
  """
  @type issue_formatter :: (term, SourceFile.t, Keyword.t -> [Issue.t])

  defmacro __using__(_opts) do
    quote do
      @behaviour Credo.Check.Consistency.Collector

      alias Credo.Issue
      alias Credo.SourceFile
      alias Credo.Execution
      alias Credo.Check.Consistency.Collector

      @spec create_issues(
        [SourceFile.t], Execution.t, Keyword.t, Collector.issue_formatter) :: atom
      def create_issues(source_files, exec, params, issue_formatter) when is_list(source_files) and is_function(issue_formatter) do
        source_files
        |> Collector.issues(__MODULE__, params, issue_formatter)
        |> Enum.each(&(Collector.append_issue_via_issue_service(&1, exec)))

        :ok
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
      {most_frequent_match, _frequency} =
        Enum.max_by(frequencies, &elem(&1, 1))

      frequencies_per_file
      |> files_with_issues(most_frequent_match)
      |> Enum.flat_map(&issue_formatter.(most_frequent_match, &1, params))
    else
      []
    end
  end

  def append_issue_via_issue_service(%Issue{filename: filename} = issue, exec) do
    Issues.append(exec, %SourceFile{filename: filename}, issue)
  end

  defp files_with_issues(frequencies_per_file, most_frequent_match) do
    Enum.reduce(frequencies_per_file, [],
      fn({file, stats}, acc) ->
        unexpected_matches = Map.keys(stats) -- [most_frequent_match]

        if unexpected_matches != [], do: [file | acc], else: acc
      end)
  end

  defp total_frequencies(frequencies_per_file) do
    Enum.reduce(frequencies_per_file, %{},
      fn({_, file_stats}, stats) ->
        Map.merge(stats, file_stats, fn(_k, f1, f2) -> f1 + f2 end)
      end)
  end
end
