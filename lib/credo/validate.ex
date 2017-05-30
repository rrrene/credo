defmodule Credo.ConfigFile.Validate do
  @moduledoc """
    This module contains the logic for parsing a `.credo.exs` config file and
    determining if it is valid or not. If at least one file is invalid, then we
    halt execution and return information to the user on how to fix the issue to
    make their files valid.
  """

  alias Credo.SourceFile

  def all_files(config_files, error_func \\ &fail_and_report/1) do
    errors = config_files
               |> Enum.map(&single_file/1)
               |> List.flatten
    if length(errors) != 0 do
      error_func.(errors)
    else
      config_files
    end
  end

  defp single_file(config_file) when is_binary(config_file) do
    config_file
      |> File.read!
      |> SourceFile.parse(config_file)
      |> SourceFile.ast
      |> validate_parsed(config_file)
  end

  defp validate_parsed(ast, config_file) do
    beginning_error = [{:error, "Missing `name` key in `#{config_file}`"}]
    errors = Credo.Code.prewalk(ast, &validate_name_key/2, beginning_error)
    errors = Credo.Code.prewalk(ast, &validate_requires/2, errors)
    Credo.Code.prewalk(ast, &validate_checks/2, errors)
  end

  defp validate_name_key({:%{}, _, args} = ast, errors) do
    if Keyword.has_key?(args, :name) do
      {ast, []}
    else
      {ast, errors}
    end
  end
  defp validate_name_key(ast, errors), do: {ast, errors}

  defp validate_requires([{:%{}, _, args}] = ast, errors) do
    if Keyword.has_key?(args, :requires) do
      args[:requires]
        |> Enum.filter(&File.exists?/1)
        |> Enum.each(&Code.load_file/1)

      new_errors = args[:requires]
                   |> Enum.reject(&File.exists?/1)
                   |> Enum.map(fn(file_path) ->
                       {:error, "`#{file_path}` is not a valid file path"}
                     end)

      {ast, [new_errors | errors]}
    else
      {ast, errors}
    end
  end
  defp validate_requires(ast, errors), do: {ast, errors}

  defp validate_checks([{:%{}, _, args}] = ast, errors) do
    if Keyword.has_key?(args, :checks) do
      new_errors = args[:checks]
                   |> Enum.map(&validate_check/1)
                   |> Enum.reject(&is_atom/1)
      {ast, [new_errors | errors]}
    else
      {ast, errors}
    end
  end
  defp validate_checks(ast, errors), do: {ast, errors}

  defp validate_check({:{}, _, [{:__aliases__, [line: line_no], _}] = args}) do
    {[module], _} = Code.eval_quoted(args)
    ensure_compiled(module, line_no)
  end
  defp validate_check({{:__aliases__, [line: line_no], _} = args, _}) do
    {module, _} = Code.eval_quoted(args)
    ensure_compiled(module, line_no)
  end

  defp ensure_compiled(module, line_no) do
    if Code.ensure_compiled?(module) do
      :ok
    else
      {:error, "#{module} on line #{line_no} is not a valid check"}
    end
  end

  defp fail_and_report(errors) do
    Enum.each(errors, fn({:error, reason}) -> IO.puts(reason) end)
    exit(1)
  end
end
