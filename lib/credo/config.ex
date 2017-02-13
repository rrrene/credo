defmodule Credo.Config do
  @doc """
  Every run of Credo is configured via a `Config` object, which is created and
  manipulated via the `Credo.Config` module.
  """

  defstruct args:               [],
            files:              nil,
            source_files:       [],
            color:              true,
            checks:             nil,
            requires:           [],
            strict:             false,
            check_for_updates:  true, # checks if there is a new version of Credo

            # options, set by the command line
            min_priority:       0,
            help:               false,
            version:            false,
            verbose:            false,
            all:                false,
            format:             nil,
            only_checks:        nil,
            ignore_checks:      nil,
            crash_on_error:     true,
            read_from_stdin:    false,

            # state, which is maintained over the course of Credo's execution
            skipped_checks:     nil,
            assigns:            %{},
            lint_attribute_map: %{} # maps filenames to @lint attributes

  @doc """
  Returns the checks that should be run for a given `config` object.

  Takes all checks from the `checks:` field of the config, matches those against
  any patterns to include or exclude certain checks given via the command line.
  """
  def checks(%__MODULE__{checks: checks, only_checks: only_checks, ignore_checks: ignore_checks}) do
    match_regexes =
      only_checks
      |> List.wrap
      |> to_match_regexes

    ignore_regexes =
      ignore_checks
      |> List.wrap
      |> to_match_regexes

    checks
    |> Enum.filter(&match_regex(&1, match_regexes, true))
    |> Enum.reject(&match_regex(&1, ignore_regexes, false))
  end

  defp match_regex(_tuple, [], default_for_empty), do: default_for_empty
  defp match_regex(tuple, regexes, _default_for_empty) do
    check_name =
      tuple
      |> Tuple.to_list
      |> List.first
      |> to_string

    Enum.any?(regexes, &Regex.run(&1, check_name))
  end

  defp to_match_regexes(list) do
    Enum.map(list, fn(match_check) ->
      {:ok, match_pattern} = Regex.compile(match_check, "i")
      match_pattern
    end)
  end

  @doc """
  Sets the config values which `strict` implies (if applicable).
  """
  def set_strict(%__MODULE__{strict: true} = config) do
    %__MODULE__{config | all: true, min_priority: -99}
  end
  def set_strict(%__MODULE__{strict: false} = config) do
    %__MODULE__{config | all: false, min_priority: 0}
  end
  def set_strict(config), do: config

  def get_assign(config, name) do
    Map.get(config.assigns, name)
  end

  def put_assign(config, name, value) do
    %__MODULE__{config | assigns: Map.put(config.assigns, name, value)}
  end

  def put_source_files(config, source_files) do
    %__MODULE__{config | source_files: source_files}
  end
end
