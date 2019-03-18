defmodule Credo.Check.Consistency.Filenames do
  @moduledoc false

  @checkdoc """
  If a file contains a single module, its filename should match the name of the module.

      # preferred

      # lib/foo/bar.exs
      defmodule Foo.Bar, do: nil

      # lib/foo/bar/bar.exs
      defmodule Foo.Bar, do: nil

      # lib/foo/foo.exs
      defmodule Foo, do: nil

      # lib/foo.exs
      defmodule Foo, do: nil

      # lib/foo/exceptions.exs
      defmodule Foo.FirstException, do: nil
      defmodule Foo.SecondException, do: nil

      # NOT preferred

      # lib/foo.exs
      defmodule Bar, do: nil

      # lib/foo/schemas/bar.exs
      defmodule Foo.Bar, do: nil
  """
  @explanation [check: @checkdoc]

  use Credo.Check, base_priority: :low

  alias Credo.Code

  @doc false
  def run(source_file, params \\ []) do
    excluded_paths = Keyword.get(params, :excluded_paths, [])
    acronyms = Keyword.get(params, :acronyms, [])
    issue_meta = IssueMeta.for(source_file, params)

    source_file.filename
    |> String.starts_with?(excluded_paths)
    |> if do
      []
    else
      source_file
      |> Credo.SourceFile.ast()
      |> root_modules()
      |> issues(issue_meta, source_file, acronyms)
    end
  end

  defp issues([{module_name, line_no}], issue_meta, source_file, acronyms) do
    [root | _] = Path.split(source_file.filename)
    extension = Path.extname(source_file.filename)
    expected_filenames = valid_filenames(module_name, root, extension, acronyms)

    if source_file.filename in expected_filenames do
      []
    else
      [issue_for(issue_meta, line_no, source_file, expected_filenames, module_name)]
    end
  end

  defp issues(_, _, _, _), do: []

  defp root_modules({:__block__, _, statements}) do
    Enum.reduce(statements, [], &process_root_statement/2)
  end

  defp root_modules({:defmodule, _, _} = statement) do
    process_root_statement(statement, [])
  end

  defp root_modules(_), do: []

  defp process_root_statement({:defmodule, opts, _} = module, acc) do
    name = Code.Module.name(module)
    line_no = Keyword.get(opts, :line)

    [{name, line_no} | acc]
  end

  defp process_root_statement(_, acc), do: acc

  defp issue_for(issue_meta, line_no, %{filename: filename}, expected_filenames, full_name) do
    format_issue(
      issue_meta,
      message: """
      The module defined in `#{filename}` is not named consistently with the filename. The file should be named either:
      #{inspect(expected_filenames)}
      """,
      trigger: full_name,
      line_no: line_no
    )
  end

  def valid_filenames(module, root, extension, acronyms) when is_binary(module) do
    parts =
      module
      |> replace_acronyms(acronyms)
      |> Macro.underscore()
      |> Path.split()

    filenames =
      parts
      |> Enum.with_index()
      |> Enum.map(fn {_, index} ->
        parts
        |> Enum.split(index)
        |> merge_filename_parts()
        |> Enum.reject(&match?("", &1))
        |> Path.join()
        |> (&"#{root}/#{&1}#{extension}").()
      end)
      |> Enum.reverse()

    [shortest_filename | _] = filenames

    # We want to support a `Foo` module in either `lib/foo.ex` or `lib/foo/foo.ex`.
    duplicated_filename = String.replace(shortest_filename, ~r/\/([^.\/]+)(\..+)$/, "/\\1/\\1\\2")

    [duplicated_filename] ++ filenames
  end

  defp merge_filename_parts({[], file_parts}), do: merge_filename_parts({[""], file_parts})

  defp merge_filename_parts({directory_parts, []}),
    do: merge_filename_parts({directory_parts, [""]})

  defp merge_filename_parts({directory_parts, file_parts}) do
    [
      Path.join(directory_parts),
      Enum.join(file_parts, ".")
    ]
  end

  defp replace_acronyms(module, acronyms) do
    Enum.reduce(acronyms, module, &process_acronym/2)
  end

  defp process_acronym(string, acc) when is_binary(string) do
    downcase_string = String.downcase(string)
    String.replace(acc, string, downcase_string)
  end

  defp process_acronym({string, processed_string}, acc) do
    downcase_string = String.downcase(processed_string)
    String.replace(acc, string, downcase_string)
  end

  defp process_acronym(_, acc), do: acc
end
