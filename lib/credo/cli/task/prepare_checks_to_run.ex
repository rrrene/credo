defmodule Credo.CLI.Task.PrepareChecksToRun do
  use Credo.Execution.Task

  def call(exec, _opts \\ []) do
    source_files = Execution.get_source_files(exec)

    exec
    |> set_lint_attributes(source_files)
    |> set_config_comments(source_files)
    |> exclude_low_priority_checks(exec.min_priority - 9)
    |> exclude_checks_based_on_elixir_version
  end

  defp set_lint_attributes(exec, source_files) do
    lint_attribute_map = Credo.Check.Runner.run_linter_attribute_reader(source_files, exec)

    if Enum.any?(lint_attribute_map, fn({_, value}) -> value != [] end) do
      Credo.CLI.Output.UI.warn ""
      Credo.CLI.Output.UI.warn [:bright, :orange,
        "@lint attributes are deprecated since Credo v0.8 because they trigger\n",
        "compiler warnings on Elixir v1.4.\n",
      ]
      Credo.CLI.Output.UI.warn [:orange,
        "You can use comments to disable individual lines of code.\n",
        "To see how this works, please refer to Credo's README:\n",
        "https://github.com/rrrene/credo"
      ]
      Credo.CLI.Output.UI.warn ""
    end

    %Execution{exec | lint_attribute_map: lint_attribute_map}
  end

  defp set_config_comments(exec, source_files) do
    config_comment_map = Credo.Check.Runner.run_config_comment_finder(source_files, exec)

    %Execution{exec | config_comment_map: config_comment_map}
  end

  defp exclude_low_priority_checks(exec, below_priority) do
    checks =
      Enum.reject(exec.checks, fn
        ({check}) -> check.base_priority < below_priority
        ({_check, false}) -> true
        ({check, opts}) ->
          (opts[:priority] || check.base_priority) < below_priority
      end)

    %Execution{exec | checks: checks}
  end

  defp exclude_checks_based_on_elixir_version(exec) do
    version = System.version()
    skipped_checks = Enum.reject(exec.checks, &matches_requirement?(&1, version))
    checks = Enum.filter(exec.checks, &matches_requirement?(&1, version))

    %Execution{exec | checks: checks, skipped_checks: skipped_checks}
  end

  defp matches_requirement?({check, _}, version) do
    matches_requirement?({check}, version)
  end
  defp matches_requirement?({check}, version) do
    Version.match?(version, check.elixir_version)
  end
end
