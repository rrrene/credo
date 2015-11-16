defmodule Credo.Check.Runner do
  alias Credo.Config
  alias Credo.SourceFile

  def run(source_files, config) when is_list(source_files) do
    source_files
    |> run_checks_that_run_on_all(config)
    |> Enum.map(&Task.async(fn -> run(&1, config) end))
    |> Enum.map(&Task.await(&1, 30_000))
  end

  def run(%SourceFile{} = source_file, config) do
    checks = config |> Config.checks |> Enum.reject(&run_on_all_check?/1)

    issues = run_checks(source_file, checks, config)
    %SourceFile{source_file | issues: source_file.issues ++ issues}
  end

  def run_checks_that_run_on_all(source_files, config) do
    checks = config |> Config.checks |> Enum.filter(&run_on_all_check?/1)

    Enum.reduce(checks, source_files, fn(check_tuple, source_files) ->
      run_check(check_tuple, source_files, config)
    end)
  end

  defp run_checks(%SourceFile{} = source_file, checks, config) when is_list(checks) do
    checks
    |> Enum.flat_map(&run_check(&1, source_file, config))
  end

  defp run_check({_check, false}, source_files, _config) when is_list(source_files) do
    source_files
  end
  defp run_check({_check, false}, _source_file, _config) do
    []
  end
  defp run_check({check}, source_file, config) do
    run_check({check, []}, source_file, config)
  end
  defp run_check({check, params}, source_file, %Config{crash_on_error: true}) do
    check.run(source_file, params)
  end
  defp run_check({check, params}, source_file, _config) do
    try do
      check.run(source_file, params)
    rescue
      _ ->
        IO.puts "Error while running #{check} on #{source_file.filename}"
        []
    end
  end

  defp run_on_all_check?({check}), do: check.run_on_all?
  defp run_on_all_check?({check, _params}), do: check.run_on_all?
end
