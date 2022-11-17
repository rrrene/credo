defmodule Credo.CLI.Output.Formatter.SARIF do
  @moduledoc false

  alias Credo.Issue

  defp to_file_uri(path) do
    "file:///" <>
      (path
       |> String.replace("\\", "/")
       |> String.replace_leading("/", "")
       |> String.replace_trailing("/", "")) <> "/"
  end

  defp move_version_to_top(sarif) do
    lines = String.split(sarif, ~r{(\r\n|\r|\n)})
    version_line = Enum.at(lines, -2) <> ","
    line_number = length(lines) - 2
    line_before_version_line = String.trim_trailing(Enum.at(lines, -3), ",")

    lines
    |> List.delete_at(-2)
    |> List.insert_at(2, version_line)
    |> Enum.with_index()
    |> Enum.map_join("\n", fn
      {_, ^line_number} -> line_before_version_line
      {value, _} -> value
    end)
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

  defp issue_to_sarif(%Issue{} = issue) do
    column_end =
      if issue.column && issue.trigger do
        issue.column + String.length(to_string(issue.trigger))
      end

    rule_and_issue = {
      %{
        "id" => Credo.Code.Name.full(issue.check),
        "fullDescription" => %{
          "text" => issue.check.explanation
        },
        "properties" => %{
          "tags" => [
            issue.category
          ]
        },
        "helpUri" => "https://hexdocs.pm/credo/#{Credo.Code.Name.full(issue.check)}.html"
      },
      %{
        "ruleId" => Credo.Code.Name.full(issue.check),
        "level" => priority_to_sarif_level(issue.priority),
        "rank" => priority_to_sarif_rank(issue.priority),
        "message" => %{
          "text" => issue.message
        },
        "locations" => [
          %{
            "physicalLocation" => %{
              "artifactLocation" => %{
                "uri" => to_string(issue.filename),
                "uriBaseId" => "ROOTPATH"
              },
              "region" => %{
                "startLine" => issue.line_no,
                "startColumn" => if(issue.column, do: issue.column, else: 1),
                "endColumn" => column_end,
                "snippet" => %{
                  "text" => issue.trigger
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

    remove_nil_endcolumn(rule_and_issue, !column_end)
  end

  defp remove_nil_endcolumn(sarif, false), do: sarif

  defp remove_nil_endcolumn(sarif, true) do
    {atom1, atom2} = sarif

    {atom1,
     pop_in(atom2, ["locations", Access.at(0), "physicalLocation", "region", "endColumn"])
     |> elem(1)}
  end

  def sum_rules_and_results([head | tail], rules, results) do
    {current_rule, current_result} = head
    existing_rule = Enum.find_index(rules, fn x -> x["id"] == current_rule["id"] end)

    case existing_rule do
      nil -> sum_rules_and_results(tail, [current_rule | rules], [current_result | results])
      _ -> sum_rules_and_results(tail, rules, [current_result | results])
    end
  end

  def sum_rules_and_results([], rules, results) do
    {rules, results}
  end

  def print_issues(issues, exec) do
    issue_list = Enum.map(issues, &issue_to_sarif/1)
    {final_rules, final_results} = sum_rules_and_results(issue_list, [], [])

    sarif = %{
      "$schema" => "https://schemastore.azurewebsites.net/schemas/json/sarif-2.1.0-rtm.5.json",
      "version" => "2.1.0",
      "runs" => [
        %{
          "tool" => %{
            "driver" => %{
              "name" => "Credo",
              "informationUri" => "http://credo-ci.org/",
              "version" => "#{Credo.version()}",
              "rules" => []
            }
          },
          "results" => [],
          "originalUriBaseIds" => %{
            "ROOTPATH" => %{
              "uri" => "file:///"
            }
          }
        }
      ]
    }

    sarif
    |> put_in(["runs", Access.at(0), "tool", "driver", "rules"], final_rules)
    |> put_in(["runs", Access.at(0), "results"], final_results)
    |> put_in(
      ["runs", Access.at(0), "originalUriBaseIds", "ROOTPATH", "uri"],
      to_file_uri(exec.cli_options.path)
    )
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
end
