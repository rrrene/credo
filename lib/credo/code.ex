defmodule Credo.Code do
  def ast(source) do
    case Code.string_to_quoted(source, line: 1) do
      {:ok, ast} -> {:ok, ast}
      {:error, error} -> {:error, [issue_for(error)]}
    end
  end

  def to_lines(source) do
    source
    |> String.split("\n")
    |> Enum.with_index
    |> Enum.map(fn {line, i} -> {i + 1, line} end)
  end

  defp issue_for({line, error_message, _}) do
    %Credo.Issue{
      rule:     Error,
      category: :error,
      message:  error_message,
      line:     line
    }
  end
end
