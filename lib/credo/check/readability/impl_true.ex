defmodule Credo.Check.Readability.ImplTrue do
  use Credo.Check,
    base_priority: :normal,
    explanations: [
      check: """
      When implementing behaviour callbacks, `@impl true` indicates that a function implements a callback, but
      a better way is to note the actual behaviour being implemented, for example `@impl MyBehaviour`. This
      not only improves readability, but adds extra validation in cases where multiple behaviours are implemented
      in a single module.

      Instead of:

          @impl true
          def my_funcion() do
            ...

      use:

          @impl MyBehaviour
          def my_funcion() do
            ...

      """
    ]

  alias Credo.Code.Heredocs

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    source_file
    |> Heredocs.replace_with_spaces()
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.reduce([], &check_line(&1, &2, issue_meta))
  end

  defp check_line({line, line_number}, issues, issue_meta) do
    case String.trim(line) do
      "@impl true" -> [issue_for(issue_meta, line_number) | issues]
      _ -> issues
    end
  end

  defp issue_for(issue_meta, line_no) do
    format_issue(
      issue_meta,
      message: "@impl true should be @impl MyBehaviour",
      trigger: "@impl true",
      line_no: line_no
    )
  end
end
