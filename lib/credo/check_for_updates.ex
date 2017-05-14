defmodule Credo.CheckForUpdates do
  alias Credo.CLI.Output.UI
  alias Credo.Execution

  @doc false
  def run(%Execution{check_for_updates: true} = exec) do
    run()

    exec
  end
  def run(%Execution{check_for_updates: false} = exec) do
    exec
  end
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
      warning =
        [
          :orange, :bright, "A new Credo version is available (#{latest})",
          :reset, :orange, ", please update with `mix deps.update credo`"
        ]

      UI.warn(warning)
    end
  end

  def should_update?(all_versions, current) do
    latest = latest_version(all_versions, current)

    Version.compare(current, latest) == :lt
  end

  defp latest_version(all_versions, default) do
    including_pre_versions? = pre_version?(default)
    latest = highest_version(all_versions, including_pre_versions?)

    latest || default
  end

  defp highest_version(versions, including_pre_versions?) do
    included_versions =
      if including_pre_versions? do
        versions
      else
        Enum.reject(versions, &pre_version?/1)
      end

    List.last(included_versions)
  end

  defp pre_version?(version) do
    {:ok, version} = Version.parse(version)

    version.pre != []
  end

  defp fetch_all_hex_versions(package_name) do
    case fetch("https://hex.pm/api/packages/#{package_name}") do
      nil ->
        nil
      package_info ->
        hex_versions(package_info)
    end
  end

  defp fetch(url) do
    :inets.start()
    :ssl.start()
    response = :httpc.request(:get, {String.to_char_list(url),
                                    [{'User-Agent', user_agent()},
                                     {'Accept', 'application/vnd.hex+erlang'}]
                                    }, [], [])

    convert_response_body(response)
  end

  defp user_agent do
    'Credo/#{Credo.version} (Elixir/#{System.version}) (OTP/#{otp_release()})'
  end

  defp otp_release do
    :erlang.list_to_binary :erlang.system_info(:otp_release)
  end

  defp convert_response_body({:ok, {_status, _headers, body}}) do
    body
    |> IO.iodata_to_binary()
    |> :erlang.binary_to_term()
  end
  defp convert_response_body(_), do: nil

  defp hex_versions(nil), do: nil
  defp hex_versions(%{"releases" => releases}) do
    Enum.map(releases, &(&1["version"]))
  end
end
