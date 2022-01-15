defmodule Credo.CLI.Output.Formatter.JsonTest do
  use Credo.Test.Case

  alias Credo.CLI.Output.Formatter.JSON

  test "print_map/1 does not raise when map contains a regex" do
    JSON.print_map(%{"option" => ~r/foo/})
  end

  test "prepare_for_json/1 converts keys and values invalid in json" do
    assert JSON.prepare_for_json(%{
             "bool" => true,
             "list" => ["a", %{"a" => "b", "b" => ~r/foo/}],
             "map" => %{"c" => "d", "e" => ["f", 8, ~r/foo/]},
             "number" => 5,
             "regex" => ~r/foo/,
             "string" => "a",
             "tuple" => {"a", 2, ~r/foo/},
             :atom_key => 0,
             {"tuple", "key"} => 1,
             0 => 2
           }) == %{
             "bool" => true,
             "list" => ["a", %{"a" => "b", "b" => "~r/foo/"}],
             "map" => %{"c" => "d", "e" => ["f", 8, "~r/foo/"]},
             "number" => 5,
             "regex" => "~r/foo/",
             "string" => "a",
             "tuple" => ["a", 2, "~r/foo/"],
             :atom_key => 0,
             ~s({"tuple", "key"}) => 1,
             0 => 2
           }
  end
end
