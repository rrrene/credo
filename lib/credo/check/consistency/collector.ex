defmodule Credo.Check.Consistency.Collector do
  @moduledoc """
  Modules performing consistency checking should use `Collector` when
  the amount of matches is expected to be high
  (e.g. when counting line breaks throughout every file).
  """

  alias Credo.Issue
  alias Credo.SourceFile

  @doc """
  `collect_values` returns a map of matches and their frequencies
  (e.g. %{with_space: 50, without_space: 40}) for a given file.
  """
  @callback collect_values(source_file :: SourceFile.t, params :: Keyword.t)
    :: %{term => non_neg_integer}

  @doc """
  `find_locations` returns metadata for each occurrence of a match
  in a given file. It is called only when the file is known to contain
  the match.
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
        {file, collector.collect_values(file, params)}
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
