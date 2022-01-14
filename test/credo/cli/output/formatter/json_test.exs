defmodule Credo.CLI.Output.Formatter.JsonTest do
  use Credo.Test.Case

  alias Credo.CLI.Output.Formatter.JSON

  test "print_map/1 does not raise when map contains a regex" do
    assert JSON.print_map(%{"option" => ~r/foo/}) == nil
  end

  test "prepare_for_json/1 converts values invalid in json" do
    assert JSON.prepare_for_json(%{
             "bool" => true,
             "list" => ["a", %{"a" => "b", "b" => ~r/foo/}],
             "map" => %{"c" => "d", "e" => ["f", 8, ~r/foo/]},
             "number" => 5,
             "regex" => ~r/foo/,
             "string" => "a",
             "tuple" => {"a", 2, ~r/foo/}
           }) == %{
             "bool" => true,
             "list" => ["a", %{"a" => "b", "b" => "~r/foo/"}],
             "map" => %{"c" => "d", "e" => ["f", 8, "~r/foo/"]},
             "number" => 5,
             "regex" => "~r/foo/",
             "string" => "a",
             "tuple" => ["a", 2, "~r/foo/"]
           }
  end
end
