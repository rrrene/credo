defmodule Credo.CheckForUpdates do
  def run() do
    all_versions = all_hex_versions("credo")
    current = Credo.version

    if should_update?(all_versions, current) do
      latest = latest_version(all_versions, current)
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

  def all_hex_versions(package_name) do
    Hex.start
    Hex.Registry.open!(Hex.Registry.Server)
    Hex.Registry.prefetch([package_name])

    Hex.Registry.versions(package_name)
  end

  def should_update?(all_versions, current) do
    latest = latest_version(all_versions, current)
    Hex.Version.compare(current, latest) == :lt
  end

  defp latest_version(all_versions, default) do
    including_pre_versions? = pre_version?(default)
    latest =
      all_versions
      |> highest_version(including_pre_versions?)

    latest || default
  end

  defp highest_version(versions, including_pre_versions?) do
    if including_pre_versions? do
      versions
    else
      versions |> Enum.reject(&pre_version?/1)
    end
    |> List.last
  end

  def pre_version?(version) do
    {:ok, version} = Hex.Version.parse(version)
    version.pre != []
  end

  defp warn(value) do
    IO.puts(:stderr, Bunt.format(value))
  end
end
