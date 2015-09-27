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
end
