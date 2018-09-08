defmodule Credo.ExsLoaderTest do
  use ExUnit.Case

  test "Credo.Execution.parse_exs should work" do
    exs_string = """
      %{
        configs: [
          %{
            name: "default",
            files: %{
              included: ["lib/", "src/", "web/", "apps/"],
              excluded: [],
            },
            combine: {:hex, :combine, "0.5.2"},
            cowboy: {:hex, :cowboy, "1.0.2"},
            dirs: ["lib", "src", "test"],
            dirs_sigil: ~w(lib src test),
            dirs_regex: ~r(lib src test),
            checks: [
              {Style.MaxLineLength, priority: :low, max_length: 100},
              {Style.TrailingBlankLine},
            ]
          }
        ]
      }
    """

    expected = %{
      configs: [
        %{
          name: "default",
          files: %{
            included: ["lib/", "src/", "web/", "apps/"],
            excluded: []
          },
          combine: {:hex, :combine, "0.5.2"},
          cowboy: {:hex, :cowboy, "1.0.2"},
          dirs: ["lib", "src", "test"],
          dirs_sigil: ~w(lib src test),
          dirs_regex: ~r(lib src test),
          checks: [
            {Style.MaxLineLength, priority: :low, max_length: 100},
            {Style.TrailingBlankLine}
          ]
        }
      ]
    }

    assert expected == Credo.ExsLoader.parse(exs_string, true)
    assert expected == Credo.ExsLoader.parse(exs_string, false)
  end
end
