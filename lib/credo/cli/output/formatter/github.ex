defmodule Credo.CLI.Output.Formatter.GitHub do
  @moduledoc false

  alias Credo.CLI.Output.UI
  alias Credo.Issue
  alias Credo.Priority

  def print_issues(issues) do
    Enum.each(issues, fn issue ->
      issue
      |> to_annotation()
      |> UI.puts()
    end)
  end

  @doc """
  Converts the given `issue` to a GitHub Actions workflow command, e.g.

      ::warning file=lib/foo.ex,line=10,col=5,title=Credo.Check.Readability.ModuleDoc::message
  """
  @spec to_annotation(Issue.t()) :: String.t()
  def to_annotation(
        %Issue{
          message: message,
          filename: filename,
          column: column,
          line_no: line_no
        } = issue
      ) do
    properties =
      [
        {"file", to_string(filename)},
        {"line", line_no},
        {"col", column},
        {"endColumn", column_end(issue)},
        {"title", Credo.Code.Name.full(issue.check)}
      ]
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Enum.map_join(",", fn {key, value} ->
        "#{key}=#{escape_property(to_string(value))}"
      end)

    "::#{severity(issue)} #{properties}::#{escape_message(message)}"
  end

  defp severity(issue) do
    case Priority.to_atom(issue.priority) do
      :higher -> "error"
      :high -> "error"
      :normal -> "warning"
      _priority -> "notice"
    end
  end

  defp column_end(%Issue{column: column, trigger: trigger}) do
    if column && trigger && trigger != Issue.no_trigger() do
      column + String.length(to_string(trigger))
    end
  end

  defp escape_message(value) do
    value
    |> String.replace("%", "%25")
    |> String.replace("\r", "%0D")
    |> String.replace("\n", "%0A")
  end

  defp escape_property(value) do
    value
    |> escape_message()
    |> String.replace(":", "%3A")
    |> String.replace(",", "%2C")
  end
end
