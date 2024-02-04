ExUnit.start()

check_version =
  ~w(1.6.5 1.7.0 1.9.0)
  |> Enum.reduce([], fn version, acc ->
    # allow -dev versions so we can test before the Elixir release.
    if System.version() |> Version.match?("< #{version}-dev") do
      acc ++ [needs_elixir: version]
    else
      acc
    end
  end)

exclude = Keyword.merge([to_be_implemented: true, housekeeping: true], check_version)

ExUnit.configure(exclude: exclude)

defmodule Credo.Test.IntegrationTest do
  def run(argv) do
    parent = self()

    spawn(fn ->
      doit = fn ->
        exec = Credo.run(argv)
        send(parent, {:exec, exec})
      end

      if System.get_env("DEBUG") do
        doit.()
      else
        ExUnit.CaptureLog.capture_log(fn ->
          ExUnit.CaptureIO.capture_io(fn ->
            doit.()
          end)
        end)
      end
    end)

    receive do
      {:exec, exec} -> exec
    end
  end
end
