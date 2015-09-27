defmodule Credo.Rule.Runner do
  def run(%Credo.SourceFile{} = source_file, config, format_callback) do
    issues = run_rules(source_file, config.rules)
    source_file = %Credo.SourceFile{ source_file | errors: issues }
    format_callback.(source_file)
    source_file
  end

  def run(source_files, config, format_callback) when is_list(source_files) do
    source_files
    |> Enum.map(
        &Task.async(fn ->
          run(&1, config, fn(source_file) ->
            format_callback.(source_file)
          end)
        end)
      )
    |> Enum.map(&Task.await/1)
  end

  defp run_rules(source_file, rules) do
    rules
    |> Enum.map( &run_rule(&1, source_file) )
    |> List.flatten
  end

  defp run_rule({rule}, source_file) do
    run_rule({rule, []}, source_file)
  end
  defp run_rule({rule, custom_config}, source_file) do
    rule.test(source_file, custom_config)
  end
end
