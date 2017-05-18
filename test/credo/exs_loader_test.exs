defmodule Credo.ExsLoaderTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "Credo.Execution.parse_exs should work" do
    exs_string = """
      %{"combine": {:hex, :combine, "0.5.2"},
        "cowboy": {:hex, :cowboy, "1.0.2"},
        "dirs": ["lib", "src", "test"],
        "dirs_sigil": ~w(lib src test),
        "dirs_regex": ~r(lib src test),
        checks: [
          {Style.MaxLineLength, max_length: 100},
          {Style.TrailingBlankLine},
        ]
      }
    """
    expected =
      %{"combine": {:hex, :combine, "0.5.2"},
        "cowboy": {:hex, :cowboy, "1.0.2"},
        "dirs": ["lib", "src", "test"],
        "dirs_sigil": ~w(lib src test),
        "dirs_regex": ~r(lib src test),
        checks: [
          {Style.MaxLineLength, max_length: 100},
          {Style.TrailingBlankLine},
        ]
      }

    assert expected == Credo.ExsLoader.parse(exs_string, true)
    assert expected == Credo.ExsLoader.parse(exs_string, false)
  end

  test ".validate outputs a warning when there is an invalid config file" do
    invalid_config = %{
      configs: [
        %{
          files: %{
            included: ["lib/", "src/", "web/", "apps/"],
            excluded: [~r"/_build/", ~r"/deps/"]
          },
          requires: [],
          check_for_updates: true,
          strict: false,
          color: true,
          checks: [{Credo.Check.Consistency.ExceptionNames}]
        }
      ]
    }
    test_func = fn -> Credo.ExsLoader.validate(invalid_config) end

    refute capture_io(test_func) == ""
  end
end
