defmodule Credo.Outdated do
  def run() do
    Hex.start
    Hex.Utils.ensure_registry!()

    include_pre_versions? = false # TODO: include pre versions if running on a pre version
    current = Credo.version
    latest = latest_version(:credo, current, include_pre_versions?)
    outdated? = Hex.Version.compare(current, latest) == :lt

    if outdated? do
      [
        :orange,
        :bright,
        "A new Credo version is available (#{latest})",
        :reset,
        :orange,
        ", please update with `mix deps.update credo`"
      ]
      |> warn
    end
  end

  defp latest_version(package, default, pre?) do
    {:ok, default} = Hex.Version.parse(default)
    pre? = pre? || default.pre != []

    latest =
      package
      |> Atom.to_string
      |> Hex.Registry.get_versions
      |> highest_version(pre?)

    latest || default
  end

  defp highest_version(versions, pre?) do
    versions = if pre? do
      versions
    else
      Enum.filter(versions, fn version ->
        {:ok, version} = Hex.Version.parse(version)
        version.pre == []
      end)
    end

    List.last(versions)
  end

  defp warn(value) do
    IO.puts(:stderr, Bunt.format(value))
  end
end
