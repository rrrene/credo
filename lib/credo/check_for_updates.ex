defmodule Credo.CheckForUpdates do
  alias Credo.CLI.Output.UI
  alias Credo.Execution

  @doc false
  def run(%Execution{check_for_updates: false} = exec) do
    exec
  end
  def run(%Execution{check_for_updates: true} = exec) do
    unless probably_on_ci?() || probably_editor_integration?(exec) do
      do_run()
    end

    exec
  end

  defp do_run do
    "credo"
    |> fetch_all_hex_versions()
    |> print_update_message()
  end

  defp print_update_message(nil), do: nil
  defp print_update_message(all_versions) do
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
    response = :httpc.request(:get, {Credo.Backports.String.to_charlist(url),
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

  # Returns true if we are (probably) on a CI system.
  defp probably_on_ci? do
    circleci?() || travis?() || generic_ci?()
  end

  defp generic_ci?, do: System.get_env("CI") == "true"

  defp circleci?, do: System.get_env("CIRCLECI") == "true"

  defp travis?, do: System.get_env("TRAVIS") == "true"

  defp probably_editor_integration?(%Execution{strict: true}) do
    true
  end
  defp probably_editor_integration?(%Execution{format: "flycheck"}) do
    true
  end
  defp probably_editor_integration?(%Execution{read_from_stdin: true}) do
    true
  end
  defp probably_editor_integration?(_exec), do: false

end
