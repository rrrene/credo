ExUnit.start()

Path.wildcard("test/support/*.exs")
|> Enum.each(&Code.require_file/1)

check_version =
  ~w(1.6.5 1.7.0)
  |> Enum.reduce([], fn version, acc ->
    # allow -dev versions so we can test before the Elixir release.
    if System.version() |> Version.match?("< #{version}-dev") do
      acc ++ [needs_elixir: version]
    else
      acc
    end
  end)

exclude = Keyword.merge([to_be_implemented: true], check_version)

ExUnit.configure(exclude: exclude)

defmodule Credo.TestHelper do
  defmacro __using__(opts) do
    async = opts[:async] != false

    quote do
      use ExUnit.Case, async: unquote(async)

      import Credo.Test.CheckRunner
      import Credo.Test.SourceFiles
      import Credo.Test.Assertions
    end
  end
end
