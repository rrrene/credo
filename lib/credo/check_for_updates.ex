defmodule Credo.CheckForUpdates do
  def run() do
    "credo"
    |> fetch_all_hex_versions()
    |> do_run()
  end

  defp do_run(nil), do: nil
  defp do_run(all_versions) do
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
      |> warn()
    end
  end

  def should_update?(all_versions, current) do
    latest = latest_version(all_versions, current)
    Version.compare(current, latest) == :lt
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

  defp pre_version?(version) do
    {:ok, version} = Version.parse(version)
    version.pre != []
  end

  defp warn(value) do
    IO.puts(:stderr, Bunt.format(value))
  end

  defp fetch_all_hex_versions(package_name) do
    case fetch("https://hex.pm/api/packages/#{package_name}") do
      nil -> nil
      package_info -> package_info |> hex_versions()
    end
  end

  defp fetch(url) do
    :inets.start()
    :ssl.start()
    :httpc.request(:get, {String.to_charlist(url),
          [{'User-Agent', user_agent()},
           {'Accept', 'application/vnd.hex+erlang'}]}, [], [])
    |> convert_response_body()
  end

  defp user_agent do
    'Credo/#{Credo.version} (Elixir/#{System.version}) (OTP/#{System.otp_release})'
  end

  defp convert_response_body({:ok, {_status, _headers, body}}) do
    body |> IO.iodata_to_binary() |> :erlang.binary_to_term()
  end
  defp convert_response_body(_), do: nil

  defp hex_versions(nil), do: nil
  defp hex_versions(%{"releases" => releases}) do
    releases |> Enum.map(&(&1["version"]))
  end
end
