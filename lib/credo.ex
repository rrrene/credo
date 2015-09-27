defmodule Credo do
  @version Mix.Project.config[:version]

  def run(dir, formatter) do
    config = dir |> to_config
    source_files = config |> Credo.Sources.find

    Dogma.Formatter.start(source_files, formatter)
    source_files = Credo.Rule.Runner.run(source_files, config, fn(source_file) ->
      Dogma.Formatter.script(source_file, formatter)
    end)
    Dogma.Formatter.finish(source_files, formatter)

    source_files_w_issues =
      Enum.reject(source_files, &Enum.empty?(&1.errors))
      |> List.flatten

    if Enum.any?(source_files_w_issues) do
      {:error, source_files_w_issues}
    else
      :ok
    end
  end

  def version, do: @version

  defp to_config(dir), do: Credo.Config.read_or_default(dir)
end
