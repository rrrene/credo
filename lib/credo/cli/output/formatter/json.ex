defmodule Credo.CLI.Output.Formatter.JSON do
  @moduledoc false

  alias Credo.CLI.Output.UI
  alias Credo.Issue

  def print_issues(issues) do
    %{
      "issues" => Enum.map(issues, &issue_to_json/1)
    }
    |> print_map()
  end

  def print_map(map) do
    map
    |> prepare_for_json()
    |> Jason.encode!(pretty: true)
    |> UI.puts()
  end

  def prepare_for_json(term)
      when is_atom(term) or is_number(term) or is_binary(term) do
    term
  end

  def prepare_for_json(term) when is_list(term), do: Enum.map(term, &prepare_for_json/1)

  def prepare_for_json(%Regex{} = regex), do: inspect(regex)

  def prepare_for_json(%{} = term) do
    Enum.into(term, %{}, fn {key, value} ->
      {prepare_key_for_json(key), prepare_for_json(value)}
    end)
  end

  def prepare_for_json(term) when is_tuple(term) do
    term
    |> Tuple.to_list()
    |> prepare_for_json()
  end

  def prepare_for_json(term) do
    inspect(term)
  end

  defp prepare_key_for_json(key) when is_atom(key) or is_binary(key) or is_number(key) do
    key
  end

  defp prepare_key_for_json(key) do
    inspect(key)
  end

  def issue_to_json(
        %Issue{
          check: check,
          category: category,
          message: message,
          filename: filename,
          priority: priority,
          scope: scope
        } = issue
      ) do
    check_name =
      check
      |> to_string()
      |> String.replace(~r/^(Elixir\.)/, "")

    column_end =
      if issue.column && issue.trigger do
        issue.column + String.length(to_string(issue.trigger))
      end

    %{
      "check" => check_name,
      "category" => to_string(category),
      "filename" => to_string(filename),
      "line_no" => issue.line_no,
      "column" => issue.column,
      "column_end" => column_end,
      "trigger" => issue.trigger,
      "message" => message,
      "priority" => priority,
      "scope" => scope
    }
  end
end
