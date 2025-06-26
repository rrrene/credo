defmodule Credo.CLI.Output.Formatter.SARIF do
  @moduledoc false

  alias Credo.Issue

  # we use this key and Jason's key ordering to ensure that the "version"
  # is right below the "schema" key in the JSON output
  @version_placeholder_json_key "$schema__this_key_goes_to_line2__version"

  def print_issues(issues, exec) do
    issue_list =
      Enum.map(issues, fn issue ->
        issue_to_sarif(issue, exec)
      end)

    {_, final_results} = sum_rules_and_results(issue_list, [], [])

    final_rules =
      issues
      |> Enum.uniq_by(& &1.check.id())
      |> Enum.map(fn issue ->
        %{
          "id" => issue.check.id(),
          "name" => Credo.Code.Name.full(issue.check),
          "fullDescription" => %{
            "text" => issue.check.explanation() |> String.replace("`", "'"),
            "markdown" => issue.check.explanation()
          },
          "properties" => %{
            "tags" => [
              issue.category
            ]
          },
          "helpUri" => issue.check.docs_uri()
        }
      end)

    %{
      "$schema" => "https://schemastore.azurewebsites.net/schemas/json/sarif-2.1.0-rtm.5.json",
      @version_placeholder_json_key => "2.1.0",
      "runs" => [
        %{
          "tool" => %{
            "driver" => %{
              "name" => "Credo",
              "informationUri" => "http://credo-ci.org/",
              "version" => "#{Credo.version()}",
              "rules" => final_rules
            }
          },
          "results" => final_results,
          "originalUriBaseIds" => %{
            "ROOTPATH" => %{
              "uri" => to_file_uri(exec.cli_options.path)
            }
          },
          "columnKind" => "utf16CodeUnits"
        }
      ]
    }
    |> print_map()
  end

  def print_map(map) do
    map
    |> prepare_for_json()
    |> Jason.encode!(pretty: true)
    |> move_version_to_top()
    |> IO.puts()
  end

  defp prepare_for_json(term)
       when is_atom(term) or is_number(term) or is_binary(term) do
    term
  end

  defp prepare_for_json(term) when is_list(term), do: Enum.map(term, &prepare_for_json/1)

  defp prepare_for_json(%Regex{} = regex), do: inspect(regex)

  defp prepare_for_json(%{} = term) do
    Enum.into(term, %{}, fn {key, value} ->
      {prepare_key_for_json(key), prepare_for_json(value)}
    end)
  end

  defp prepare_for_json(term) when is_tuple(term) do
    term
    |> Tuple.to_list()
    |> prepare_for_json()
  end

  defp prepare_for_json(term) do
    inspect(term)
  end

  defp prepare_key_for_json(key) when is_atom(key) or is_binary(key) or is_number(key) do
    key
  end

  defp prepare_key_for_json(key) do
    inspect(key)
  end

  defp move_version_to_top(sarif) do
    String.replace(sarif, ~s("#{@version_placeholder_json_key}": "), ~s("version": "))
  end

  defp to_file_uri(path) do
    "file:///" <>
      (path
       |> String.replace("\\", "/")
       |> String.replace_leading("/", "")
       |> String.replace_trailing("/", "")) <> "/"
  end

  defp priority_to_sarif_level(priority) when is_number(priority) do
    cond do
      # :higher
      priority > 19 -> :error
      # :high
      priority in 10..19 -> :error
      # :normal
      priority in 0..9 -> :warning
      # :low
      priority in -10..-1 -> :note
      # :ignore
      priority < -10 -> :note
    end
  end

  defp priority_to_sarif_level(_), do: :warning

  defp priority_to_sarif_rank(priority) when is_number(priority) do
    cond do
      priority < -10 -> 1
      priority > 89 -> 100
      true -> priority + 11
    end
  end

  defp priority_to_sarif_rank(_), do: 0

  defp issue_to_sarif(%Issue{} = issue, exec) do
    sarif_level = priority_to_sarif_level(issue.priority)

    column_end =
      if issue.column && issue.trigger do
        issue.column + String.length(to_string(issue.trigger))
      end

    trigger =
      if issue.trigger == Credo.Issue.no_trigger() do
        ""
      else
        to_string(issue.trigger)
      end

    rule_and_issue = {
      %{
        "id" => issue.check.id(),
        "name" => Credo.Code.Name.full(issue.check),
        "fullDescription" => %{
          "text" => issue.check.explanation() |> String.replace("`", "'"),
          "markdown" => issue.check.explanation()
        },
        "properties" => %{
          "tags" => [
            issue.category
          ]
        },
        "helpUri" => issue.check.docs_uri()
      },
      %{
        "ruleId" => issue.check.id(),
        "level" => sarif_level,
        "rank" => priority_to_sarif_rank(issue.priority),
        "message" => %{
          "text" => issue.message |> String.replace("`", "'"),
          "markdown" => issue.message
        },
        "locations" => [
          %{
            "physicalLocation" => %{
              "artifactLocation" => %{
                "uri" => to_string(Path.relative_to(issue.filename, exec.cli_options.path)),
                "uriBaseId" => "ROOTPATH"
              },
              "region" => %{
                "startLine" => issue.line_no,
                "startColumn" => issue.column || 1,
                "endColumn" => column_end,
                "snippet" => %{
                  "text" => trigger
                }
              }
            },
            "logicalLocations" => [
              %{
                "fullyQualifiedName" => issue.scope
              }
            ]
          }
        ]
      }
    }

    rule_and_issue
    |> remove_nil_endcolumn(!column_end)
    |> remove_warning_level(sarif_level == :warning)
    |> remove_redundant_name(issue.check.id() == Credo.Code.Name.full(issue.check))
  end

  defp remove_nil_endcolumn(sarif, false), do: sarif

  defp remove_nil_endcolumn(sarif, true) do
    {atom1, atom2} = sarif

    {atom1,
     pop_in(atom2, ["locations", Access.at(0), "physicalLocation", "region", "endColumn"])
     |> elem(1)}
  end

  defp remove_warning_level(sarif, false), do: sarif

  defp remove_warning_level(sarif, true) do
    {atom1, atom2} = sarif

    {atom1, pop_in(atom2, ["level"]) |> elem(1)}
  end

  defp remove_redundant_name(sarif, false), do: sarif

  defp remove_redundant_name(sarif, true) do
    {atom1, atom2} = sarif

    {pop_in(atom1, ["name"]) |> elem(1), atom2}
  end

  defp sum_rules_and_results([head | tail], rules, results) do
    {current_rule, current_result} = head
    existing_rule = Enum.find_index(rules, fn x -> x["id"] == current_rule["id"] end)

    case existing_rule do
      nil -> sum_rules_and_results(tail, [current_rule | rules], [current_result | results])
      _ -> sum_rules_and_results(tail, rules, [current_result | results])
    end
  end

  defp sum_rules_and_results([], rules, results) do
    {rules, results}
  end
end
