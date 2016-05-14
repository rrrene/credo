defmodule Credo.Outdated do
  def run() do
    Hex.start
    Hex.Utils.ensure_registry!()

    include_pre_versions? = false
    current = Credo.version
    latest = latest_version(:credo, current, include_pre_versions?)
    outdated? = Hex.Version.compare(current, latest) == :lt

    if outdated? do
      [
        :orange,
        :bright,
        "There is a newer version of Credo available: ",
        :reset,
        :orange,
        "#{latest} (use `mix deps.update credo` to upgrade)"
      ]
      |> Bunt.puts
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
end
