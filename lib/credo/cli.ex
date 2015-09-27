defmodule Credo.CLI do
  def main(argv) do
    case run(argv) do
      :ok         -> System.halt(0)
      {:error, _} -> System.halt(1)
    end
  end

  defp run(argv) do
    {dir, formatter} = parse_options(argv)
    Credo.run(dir, formatter)
  end

  defp parse_options(argv) do
    switches = [format: :string]
    {switches, files, []} = OptionParser.parse(argv, switches: switches)

    dir = files |> List.first |> to_string

    format = Keyword.get(switches, :format)
    formatter = Map.get(Dogma.Formatter.formatters,
                        format,
                        Dogma.Formatter.default_formatter)
    {dir, formatter}
  end
end
