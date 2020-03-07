defmodule Credo.Check.Consistency.Collector do
  @moduledoc """
  A behavior for modules that walk through source files and
  identify consistency issues.

  When defining a consistency check, you would typically use
  this structure for the main module, responsible
  for formatting issue messages:

      defmodule Credo.Check.Consistency.SomeCheck do
        use Credo.Check, run_on_all: true

        @collector Credo.Check.Consistency.SomeCheck.Collector

        def run(source_files, exec, params) when is_list(source_files) do
          issue_formatter = &issues_for/3

          @collector.find_and_append_issues(source_files, exec, params, issue_formatter)
        end

        defp issues_for(expected, source_file, params) do
          issue_meta = IssueMeta.for(source_file, params)
          issue_locations =
            @collector.find_locations_not_matching(expected, source_file)

          Enum.map(issue_locations, fn(location) ->
            format_issue issue_meta, message: ... # write an issue message
          end)
        end

  The actual analysis would be performed by another module
  implementing the `Credo.Check.Consistency.Collector` behavior:

      defmodule Credo.Check.Consistency.SomeCheck.Collector do
        use Credo.Check.Consistency.Collector

        def collect_matches(source_file, params) do
          # ...
        end

        def find_locations_not_matching(expected, source_file) do
          # ...
        end
      end

  Read further for more information on `collect_matches/2`,
  `find_locations_not_matching/2`, and `issue_formatter`.
  """

  alias Credo.Execution.ExecutionIssues
  alias Credo.Issue
  alias Credo.SourceFile

  @doc """
  When you call `@collector.find_and_append_issues/4` inside the check module,
  the collector first counts the occurrences of different matches
  (e.g. :with_space and :without_space for a space around operators check)
  per each source file.

  `collect_matches/2` produces a map of matches as keys and their frequencies
  as values (e.g. %{with_space: 50, without_space: 40}).

  The maps for individual source files are then merged, producing a map
  that reflects frequency trends for the whole codebase.
  """
  @callback collect_matches(
              source_file :: SourceFile.t(),
              params :: Keyword.t()
            ) :: %{
              term => non_neg_integer
            }

  # Once the most frequent match is identified, the `Collector` looks up
  # source files that have other matches (e.g. both :with_space
  # and :without_space or just :without_space when :with_space is the
  # most frequent) and calls the `issue_formatter` function on them.
  #
  # An issue formatter produces a list of `Credo.Issue` structs
  # from the most frequent (expected) match, a source file
  # containing other matches, and check params
  # (the latter two are required to build an IssueMeta).
  @type issue_formatter :: (term, SourceFile.t(), Keyword.t() -> [Issue.t()])

  @doc """
  `issue_formatter` may call the `@collector.find_locations_not_matching/2`
  function to obtain additional metadata for each occurrence of
  an unexpected match in a given file.

  An example implementation that returns a list of line numbers on
  which unexpected occurrences were found:

      def find_locations_not_matching(expected, source_file) do
        traverse(source_file, fn(match, line_no, acc) ->
          if match != expected do
            acc ++ [line_no]
          else
            acc
          end
        end)
      end

      defp traverse(source_file, fun), do: ...
  """
  @callback find_locations_not_matching(
              expected :: term,
              source_file :: SourceFile.t()
            ) :: list(term)

  @optional_callbacks find_locations_not_matching: 2

  defmacro __using__(_opts) do
    quote do
      @behaviour Credo.Check.Consistency.Collector

      alias Credo.Check.Consistency.Collector
      alias Credo.Execution
      alias Credo.Issue
      alias Credo.SourceFile

      @spec find_and_append_issues(
              [SourceFile.t()],
              Execution.t(),
              Keyword.t(),
              Collector.issue_formatter()
            ) :: atom
      def find_and_append_issues(source_files, exec, params, issue_formatter)
          when is_list(source_files) and is_function(issue_formatter) do
        source_files
        |> Collector.find_issues(__MODULE__, params, issue_formatter)
        |> Enum.each(&Collector.append_issue_via_issue_service(&1, exec))

        :ok
      end
    end
  end

  def find_issues(source_files, collector, params, issue_formatter) do
    # IO.puts("#{collector}: find_issues 1")

    frequencies_per_source_file =
      source_files
      |> Enum.map(&Task.async(fn -> {&1, collector.collect_matches(&1, params)} end))
      |> Enum.map(&Task.await(&1, :infinity))

    # IO.puts("#{collector}: find_issues 2")

    frequencies = total_frequencies(frequencies_per_source_file)

    if map_size(frequencies) > 0 do
      {most_frequent_match, _frequency} = Enum.max_by(frequencies, &elem(&1, 1))

      # x =
      #   frequencies_per_source_file
      #   |> source_files_with_issues(most_frequent_match)

      # IO.puts("--- going into issue formatter #{inspect(issue_formatter)}")

      # x
      # |> Enum.flat_map(&issue_formatter.(most_frequent_match, &1, params))

      # IO.puts("#{collector}: find_issues 3")

      result =
        frequencies_per_source_file
        |> source_files_with_issues(most_frequent_match)
        |> Enum.map(&Task.async(fn -> issue_formatter.(most_frequent_match, &1, params) end))
        |> Enum.flat_map(&Task.await(&1, :infinity))

      # IO.puts("#{collector}: find_issues 4")

      result
    else
      []
    end
  end

  def append_issue_via_issue_service(%Issue{} = issue, exec) do
    ExecutionIssues.append(exec, issue)
  end

  defp source_files_with_issues(frequencies_per_file, most_frequent_match) do
    Enum.reduce(frequencies_per_file, [], fn {filename, stats}, acc ->
      unexpected_matches = Map.keys(stats) -- [most_frequent_match]

      if unexpected_matches != [] do
        [filename | acc]
      else
        acc
      end
    end)
  end

  defp total_frequencies(frequencies_per_file) do
    Enum.reduce(frequencies_per_file, %{}, fn {_, file_stats}, stats ->
      Map.merge(stats, file_stats, fn _k, f1, f2 -> f1 + f2 end)
    end)
  end
end
