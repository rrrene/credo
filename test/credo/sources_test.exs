defmodule Credo.SourcesTest do
  use ExUnit.Case

  #
  # find
  #

  test "Credo.Sources.find with credo config with included files" do
    config = %Credo.Config{files: %{excluded: [], included: ["lib/credo.ex"]}}

    assert %Credo.SourceFile{} = (Credo.Sources.find(config) |> List.first)
  end

  test "Credo.Sources.find with credo config with exclueded files" do
    config = %Credo.Config{files: %{excluded: ["lib/credo.ex"], included: ["lib/credo.ex"]}}

    expected = []
    assert expected == Credo.Sources.find(config)
  end

  test "Credo.Sources.find with list of pathes" do
    pathes = ["lib/credo.ex", "lib/credo/cli.ex"]

    expected = pathes
    assert expected == Credo.Sources.find(pathes)
  end

  test "Credo.Sources.find with binary path" do
    path = "lib/*.ex"

    expected = ["lib/credo.ex"]
    assert expected == Credo.Sources.find(path)
  end

  test "Credo.Sources.find returns source_file by module name" do
    module = GenServer

    assert %Credo.SourceFile{} = Credo.Sources.find(module)
  end

  #
  # exclude
  #

  test "Credo.Sources.exclude" do
    files = ["credo.ex", "credo_test.exs", "config.exs"]
    expected = ["credo.ex"]
    assert expected == Credo.Sources.exclude(files, [~r/test/, ~r/\.exs$/])
  end

  test "Credo.Sources.exclude with directories" do
    files = ["lib/credo.ex", "lib/test/credo_test.exs", "config/config.exs"]
    expected = ["lib/credo.ex", "lib/test/credo_test.exs"]
    assert expected == Credo.Sources.exclude(files, ["config/"])
  end

  test "Credo.Sources.exclude with globs" do
    files = ["lib/credo.ex", "lib/test/credo_test.exs", "config/config.exs"]
    expected = ["lib/test/credo_test.exs", "config/config.exs"]
    assert expected == Credo.Sources.exclude(files, ["lib/*.ex"])
  end
end
