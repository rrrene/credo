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
              {Credo.Check.Style.MaxLineLength, priority: :low, max_length: 100},
              {Credo.Check.Style.TrailingBlankLine},
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
            {Credo.Check.Style.MaxLineLength, priority: :low, max_length: 100},
            {Credo.Check.Style.TrailingBlankLine}
          ]
        }
      ]
    }

    assert {:ok, expected} == Credo.ExsLoader.parse(exs_string, true)
    assert {:ok, expected} == Credo.ExsLoader.parse(exs_string, false)
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

    assert expected == Credo.ExsLoader.parse(exs_string, true)
    assert expected == Credo.ExsLoader.parse(exs_string, false)
  end

  test "Should execute config code only w/o safe mode" do
    exs_string = """
      %{
        configs: [
          %{
            name: "default",
            dirs: ~w(LIB SRC TEST) |> Enum.map(&String.downcase/1),
            checks: [
              {Credo.Check.Style.MaxLineLength, priority: :low, max_length: 100},
              {Credo.Check.Style.TrailingBlankLine},
            ]
          }
        ]
      }
    """

    expected = %{
      configs: [
        %{
          name: "default",
          dirs: ["lib", "src", "test"],
          checks: [
            {Credo.Check.Style.MaxLineLength, priority: :low, max_length: 100},
            {Credo.Check.Style.TrailingBlankLine}
          ]
        }
      ]
    }

    assert_raise ArgumentError, fn ->
      Credo.ExsLoader.parse(exs_string, true)
    end

    assert expected == Credo.ExsLoader.parse(exs_string)
  end

  test "Should parse the requires field only w/o safe mode" do
    exs_string = """
      %{
        configs: [
          %{
            name: "default",
            requires: ["code.ex", "othercode.ex"]
          }
        ]
      }
    """

    expected_unsafe = %{
      configs: [
        %{
          name: "default",
          requires: ["code.ex", "othercode.ex"]
        }
      ]
    }

    expected_safe = %{
      configs: [
        %{
          name: "default",
        }
      ]
    }

    assert expected_unsafe == Credo.ExsLoader.parse(exs_string)
    assert expected_safe == Credo.ExsLoader.parse(exs_string, true)
  end

  test "Should allow custom checks only w/o safe mode" do
    exs_string = """
      %{
        configs: [
          %{
            name: "default",
            checks: [
              {Credo.Check.Style.MaxLineLength, priority: :low, max_length: 100},
              {MyModule.MyCheck.Style.TrailingBlankLine},
            ]
          }
        ]
      }
    """

    expected = %{
      configs: [
        %{
          name: "default",
          checks: [
            {Credo.Check.Style.MaxLineLength, priority: :low, max_length: 100},
            {MyModule.MyCheck.Style.TrailingBlankLine},
          ]
        }
      ]
    }

    assert_raise ArgumentError, fn ->
      Credo.ExsLoader.parse(exs_string, true)
    end

    assert expected == Credo.ExsLoader.parse(exs_string)
  end

end
