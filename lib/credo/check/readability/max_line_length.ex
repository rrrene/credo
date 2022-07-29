defmodule Credo.Check.Readability.MaxLineLength do
  use Credo.Check,
    base_priority: :low,
    tags: [:formatter],
    param_defaults: [
      max_length: 120,
      ignore_definitions: true,
      ignore_heredocs: true,
      ignore_specs: false,
      ignore_sigils: true,
      ignore_strings: true,
      ignore_urls: true
    ],
    explanations: [
      check: """
      Checks for the length of lines.

      Ignores function definitions and (multi-)line strings by default.
      """,
      params: [
        max_length: "The maximum number of characters a line may consist of.",
        ignore_definitions: "Set to `true` to ignore lines including function definitions.",
        ignore_specs: "Set to `true` to ignore lines including `@spec`s.",
        ignore_sigils: "Set to `true` to ignore lines that are sigils, e.g. regular expressions.",
        ignore_strings: "Set to `true` to ignore lines that are strings or in heredocs.",
        ignore_urls: "Set to `true` to ignore lines that contain urls."
      ]
    ]

  alias Credo.Code.Heredocs
  alias Credo.Code.Sigils
  alias Credo.Code.Strings

  @def_ops [:def, :defp, :defmacro]
  @url_regex ~r/[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)/

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)
    max_length = Params.get(params, :max_length, __MODULE__)

    ignore_definitions = Params.get(params, :ignore_definitions, __MODULE__)

    ignore_specs = Params.get(params, :ignore_specs, __MODULE__)
    ignore_sigils = Params.get(params, :ignore_sigils, __MODULE__)
    ignore_strings = Params.get(params, :ignore_strings, __MODULE__)
    ignore_heredocs = Params.get(params, :ignore_heredocs, __MODULE__)
    ignore_urls = Params.get(params, :ignore_urls, __MODULE__)

    definitions = Credo.Code.prewalk(source_file, &find_definitions/2)
    specs = Credo.Code.prewalk(source_file, &find_specs/2)

    source =
      if ignore_heredocs do
        Heredocs.replace_with_spaces(source_file, "")
      else
        SourceFile.source(source_file)
      end

    source =
      if ignore_sigils do
        Sigils.replace_with_spaces(source, "")
      else
        source
      end

    lines = Credo.Code.to_lines(source)

    lines_for_comparison =
      if ignore_strings do
        source
        |> Strings.replace_with_spaces("", " ", source_file.filename)
        |> Credo.Code.to_lines()
      else
        lines
      end

    lines_for_comparison =
      if ignore_urls do
        Enum.reject(lines_for_comparison, fn {_, line} -> line =~ @url_regex end)
      else
        lines_for_comparison
      end

    Enum.reduce(lines_for_comparison, [], fn {line_no, line_for_comparison}, issues ->
      if String.length(line_for_comparison) > max_length do
        if refute_issue?(line_no, definitions, ignore_definitions, specs, ignore_specs) do
          issues
        else
          {_, line} = Enum.at(lines, line_no - 1)

          [issue_for(line_no, max_length, line, issue_meta) | issues]
        end
      else
        issues
      end
    end)
  end

  # TODO: consider for experimental check front-loader (ast)
  for op <- @def_ops do
    defp find_definitions({unquote(op), meta, arguments} = ast, definitions)
         when is_list(arguments) do
      {ast, [meta[:line] | definitions]}
    end
  end

  defp find_definitions(ast, definitions) do
    {ast, definitions}
  end

  # TODO: consider for experimental check front-loader (ast)
  defp find_specs({:spec, meta, arguments} = ast, specs) when is_list(arguments) do
    {ast, [meta[:line] | specs]}
  end

  defp find_specs(ast, specs) do
    {ast, specs}
  end

  defp refute_issue?(line_no, definitions, ignore_definitions, specs, ignore_specs) do
    ignore_definitions? =
      if ignore_definitions do
        Enum.member?(definitions, line_no)
      else
        false
      end

    ignore_specs? =
      if ignore_specs do
        Enum.member?(specs, line_no)
      else
        false
      end

    ignore_definitions? || ignore_specs?
  end

  defp issue_for(line_no, max_length, line, issue_meta) do
    line_length = String.length(line)
    column = max_length + 1
    trigger = String.slice(line, max_length, line_length - max_length)

    format_issue(
      issue_meta,
      message: "Line is too long (max is #{max_length}, was #{line_length}).",
      line_no: line_no,
      column: column,
      trigger: trigger
    )
  end
end
