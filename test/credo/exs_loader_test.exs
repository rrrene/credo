defmodule Credo.ExsLoaderTest do
  use ExUnit.Case

  @exec %Credo.Execution{}

  test "Credo.Execution.parse_exs should work" do
    exs_string = """
      %{combine: {:hex, :combine, "0.5.2"},
        cowboy: {:hex, :cowboy, "1.0.2"},
        dirs: ["lib", "src", "test"],
        dirs_sigil: ~w(lib src test),
        dirs_regex: ~r(lib src test),
        checks: [
          {Style.MaxLineLength, max_length: 100},
          {Style.TrailingBlankLine},
        ]
      }
    """

    expected = %{
      combine: {:hex, :combine, "0.5.2"},
      cowboy: {:hex, :cowboy, "1.0.2"},
      dirs: ["lib", "src", "test"],
      dirs_sigil: ~w(lib src test),
      dirs_regex: ~r(lib src test),
      checks: [
        {Style.MaxLineLength, max_length: 100},
        {Style.TrailingBlankLine}
      ]
    }

    assert {:ok, expected} == Credo.ExsLoader.parse(exs_string, "testfile.ex", @exec, true)
    assert {:ok, expected} == Credo.ExsLoader.parse(exs_string, "testfile.ex", @exec, false)
  end

  test "Credo.Execution.parse_exs should return error tuple" do
    exs_string = """
    %{
      configs: [
        %{
          name: "default",
          files: %{
            included: ["lib/", "src/", "web/", "apps/"],
            excluded: []
          }
          checks: [
            {Credo.Check.Readability.ModuleDoc, false}
          ]
        }
      ]
    }
    """

    expected = {:error, {9, "syntax error before: ", "checks"}}

    assert expected == Credo.ExsLoader.parse(exs_string, "testfile.ex", @exec, true)
    assert expected == Credo.ExsLoader.parse(exs_string, "testfile.ex", @exec, false)
  end
end
