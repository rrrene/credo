defmodule Credo.ExsLoaderTest do
  use ExUnit.Case

  @exec %Credo.Execution{}

  test "Credo.Execution.parse_exs should work" do
    exs_string = ~S'''
      %{combine: {:hex, :combine, "0.5.2"},
        cowboy: {:hex, :cowboy, "1.0.2"},
        dirs: ["lib", "src", "test"],
        dirs_sigil: ~w(lib src test),
        checks: [
          {Style.MaxLineLength, max_length: 100},
          {Style.TrailingBlankLine},
        ]
      }
    '''

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

    assert {:ok, expected} == Credo.ExsLoader.parse(exs_string, "testfile.ex", @exec, true)
    assert {:ok, expected} == Credo.ExsLoader.parse(exs_string, "testfile.ex", @exec, false)
  end

  test "Credo.Execution.parse_exs should work for regex across Erlang versions" do
    exs_string = ~S'''
      %{regex: ~r(lib src test)}
    '''

    expected = %{regex: ~r(lib src test)}

    {:ok, safe} = Credo.ExsLoader.parse(exs_string, "testfile.ex", @exec, true)
    {:ok, unsafe} = Credo.ExsLoader.parse(exs_string, "testfile.ex", @exec, false)

    assert Regex.source(expected.regex) == Regex.source(safe.regex)
    assert Regex.source(expected.regex) == Regex.source(unsafe.regex)
  end

  test "Credo.Execution.parse_exs should return error tuple" do
    exs_string = ~S'''
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
    '''

    expected = {:error, {9, "syntax error before: ", "checks"}}

    assert expected == Credo.ExsLoader.parse(exs_string, "testfile.ex", @exec, true)
    assert expected == Credo.ExsLoader.parse(exs_string, "testfile.ex", @exec, false)
  end
end
