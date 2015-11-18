defmodule Credo.SourcesTest do
  use ExUnit.Case

  test "Credo.Sources.find" do
    files = ["credo.ex", "credo_test.exs", "config.exs"]
    expected = ["credo.ex"]
    assert expected == Credo.Sources.exclude(files, [~r/test/, ~r/\.exs$/])
  end

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
