defmodule Credo.Check.RunnerExperimental do
  @moduledoc false

  # This module is responsible for running checks based on the context represented
  # by the current `Credo.Execution`.

  alias Credo.CLI.Output.UI
  alias Credo.Execution

  @doc """
  Runs all checks on all source files (according to the config).
  """
  def run(source_files, exec) when is_list(source_files) do
    exec
    |> Execution.checks()
    |> warn_about_ineffective_patterns(exec)
    |> fix_old_notation_for_checks_without_params()
    |> Enum.map(&Task.async(fn -> run_on_all_source_files(&1, exec, source_files) end))
    |> Enum.each(&Task.await(&1, :infinity))

    :ok
  end

  defp run_on_all_source_files({check, params}, exec, source_files) do
    check.run_on_all_source_files(exec, source_files, params)
  end

  defp fix_old_notation_for_checks_without_params(checks) do
    Enum.map(checks, fn
      {check} -> {check, []}
      {check, params} -> {check, params}
    end)
  end

  defp warn_about_ineffective_patterns(
         {checks, _included_checks, []},
         %Execution{ignore_checks: [_ | _] = ignore_checks}
       ) do
    UI.warn([
      :red,
      "A pattern was given to ignore checks, but it did not match any: ",
      inspect(ignore_checks)
    ])

    checks
  end

  defp warn_about_ineffective_patterns({checks, _, _}, _) do
    checks
  end
end
