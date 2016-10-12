defmodule Credo.Check.Consistency.Helper do
  @moduledoc """
  This module contains functions that are used by several
  consistency checks.

  # On properties and property lists

  Imagine a test that checks files for whether they use soft-tabs or hard-tabs
  for indentation.

  property_values in this case might be :spaces and :tabs

    {value, meta}

  value can be anything imaginable, meta should contain a filename
  (optionally with a line_no, trigger, etc.) or an AST

  a `property_list` is simply a list of property_values

    [
      {value, meta},
      {value, meta},
      ...
    ]

  a property_tuple is a tuple of {property_list, source_file}

  So in our example a property_tuple

      {[{:spaces, meta}, {:tabs, meta2}], %SourceFile{}}

  which would indicate that the check on that SourceFile showed that it mixes
  different indentation styles within one file.
  """

  alias Credo.Check.PropertyValue
  alias Credo.IssueMeta

  @doc """

  `callback` is expected to return a tuple `{property_values, most_picked_prop_value}`.
  """
  def most_picked_prop(source_files, callback) when is_list(source_files) and is_function(callback) do
    properties =
      source_files
      |> Enum.map(callback)
      |> Enum.sort

    {properties, most_picked_prop_value(properties)}
  end

  @doc """
  Returns a tuple `{most_picked_prop, picked_count, total_count}`
  """
  def most_picked_prop_value(list) when is_list(list) do
    all_property_values =
      list
      |> Enum.flat_map(fn({property_list, _source_file}) -> PropertyValue.get(property_list) end)

    result =
      all_property_values
      |> Enum.map(fn(prop_val) ->
          current_property_value = PropertyValue.get(prop_val)

          prop_size =
            all_property_values
            |> Enum.filter(fn(property_value) ->
                PropertyValue.get(property_value) == current_property_value
              end)
            |> Enum.count

          case prop_size do
            0 -> nil
            _ -> {prop_size, current_property_value}
          end
        end)
      |> Enum.reject(&is_nil/1)
      |> Enum.sort
      |> List.last

    case result do
      {prop_count, prop_name} -> {prop_name, prop_count, Enum.count(all_property_values)}
      nil -> nil
    end
  end

  @doc """
  Runs a given set of `pattern_mods` (CodePattern modules) against a given
  set of `source_files`.

  Returns a tuple: {property_tuples, most_picked}
  """
  def run_code_patterns(source_files, pattern_mods, params) do
    source_files
    |> most_picked_prop(&create_property_tuples(&1, pattern_mods, params))
  end

  @doc """
  Takes all the `property_tuples` from run_code_patterns and creates issues in
  all source_files that do not sport the most_picked property_value.

  Does call `new_issue_fun/4` when necessary to create a new issue.
  """
  def append_issues_via_issue_service({property_tuples, most_picked}, new_issue_fun, params) do
    property_tuples
    |> Enum.map(&append_issues_if_necessary(&1, most_picked, new_issue_fun, params))
  end

  defp append_issues_if_necessary({_prop_list, _source_file}, nil, _, _) do
    nil
  end
  defp append_issues_if_necessary({prop_list, source_file}, most_picked, new_issue_fun, params) do
    {expected_prop, picked_count, total_count} = most_picked
    case prop_list |> PropertyValue.get |> Enum.uniq do
      [^expected_prop] ->
        nil
      list ->
        prop_list
        |> Enum.map(fn(prop) ->
            value = PropertyValue.get(prop)
            if value != expected_prop && Enum.member?(list, value) do
              issue_meta = IssueMeta.for(source_file, params)
              new_issue_fun.(issue_meta, prop, expected_prop, picked_count, total_count)
            end
          end)
        |> List.flatten
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq  # TODO: should we really "squash" the issues here?
        |> Enum.each(fn(issue) ->
            Credo.Service.SourceFileIssues.append(source_file, issue)
          end)
    end
  end

  defp create_property_tuples(source_file, pattern_mods, params) do
    list = property_list_for(source_file, pattern_mods, params)
    {list, source_file}
  end

  defp property_list_for(source_file, pattern_mods, params) do
    pattern_mods
    |> collect_property_values(source_file, params)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq
  end

  defp collect_property_values(pattern_mods, source_file, params) do
    pattern_mods
    |> Enum.reduce([], fn(pattern_mod, acc) ->
        result = pattern_mod.property_value_for(source_file, params)
        acc ++ List.wrap(result)
      end)
  end

end
