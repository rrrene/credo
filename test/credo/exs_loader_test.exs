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

    assert {:ok, safe_result} = Credo.ExsLoader.parse(exs_string, "testfile.ex", @exec, true)
    assert {:ok, unsafe_result} = Credo.ExsLoader.parse(exs_string, "testfile.ex", @exec, false)

    expected = %{
      combine: {:hex, :combine, "0.5.2"},
      cowboy: {:hex, :cowboy, "1.0.2"},
      dirs: ["lib", "src", "test"],
      dirs_sigil: ~w(lib src test),
      checks: [
        {Style.MaxLineLength, max_length: 100},
        {Style.TrailingBlankLine}
      ]
    }

    assert expected == Map.delete(safe_result, :dirs_regex)
    assert expected == Map.delete(unsafe_result, :dirs_regex)

    # Erlang 28.0
    # match on source field instead of the whole regex since
    # re_pattern contains reference for each regular expression
    assert "lib src test" == safe_result.dirs_regex.source
    assert "lib src test" == unsafe_result.dirs_regex.source
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
