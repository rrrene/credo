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

  test ".validate outputs a warning when the name key is missing in config" do
    invalid_config = %{
      configs: [
        %{
          checks: [{Credo.Check.Consistency.ExceptionNames}]
        }
      ]
    }
    test_func = fn -> Credo.ExsLoader.validate(invalid_config) end

    refute capture_io(test_func) == ""
  end

  test ".validate outputs a warning when including a file that does not exist" do
    invalid_config = %{
      configs: [
        %{
          requires: ["not_there.ex"],
          name: "default"
        }
      ]
    }
    test_func = fn -> Credo.ExsLoader.validate(invalid_config) end

    refute capture_io(test_func) == ""
  end

  test ".validate outputs a warning when including a check that does not exist" do
    invalid_config = %{
      configs: [
        %{
          name: "default",
          checks: [{Credo.Check.Consistency.NonExistantCheck}]
        }
      ]
    }
    test_func = fn -> Credo.ExsLoader.validate(invalid_config) end

    refute capture_io(test_func) == ""
  end
end
