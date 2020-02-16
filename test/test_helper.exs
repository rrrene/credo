ExUnit.start()

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
