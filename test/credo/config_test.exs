defmodule Credo.ConfigTest do
  use ExUnit.Case

  test "Credo.Config.from_json should work" do
    json_string = """
{
  "files": {
    "included": ["src/**/*.{ex,exs}"],
    "excluded": []
  },
  "rules": [
    ["Style.MaxLineLength", {"max_length": 100}],
    ["Style.TrailingBlankLine"]
  ]
}
    """
    expected = %Credo.Config{
      files: %{
        included: ["src/**/*.{ex,exs}"],
        excluded: []
      },
      rules: [] # TODO: implement rule parsing
    }
    assert expected == Credo.Config.from_json(json_string)
  end

  test "Credo.Config.from_json should work with incomplete values" do
    json_string = """
{
  "files": {
    "excluded": []
  }
}
    """
    expected = %Credo.Config{
      files: %{
        included: ["lib/**/*.{ex,exs}"],
        excluded: []
      },
      rules: Credo.Config.default_rules
    }
    assert expected == Credo.Config.from_json(json_string)
  end

  test "Credo.Config.read_or_default should work" do
    expected = %Credo.Config{
      files: %{
        included: ["lib/**/*.{ex,exs}"],
        excluded: []
      },
      rules: Credo.Config.default_rules
    }
    assert expected == Credo.Config.read_or_default(".")
  end

  test "Credo.Config.read_or_default should work if file is not present" do
    expected = %Credo.Config{
      files: %{
        included: ["lib/**/*.{ex,exs}"],
        excluded: []
      },
      rules: Credo.Config.default_rules
    }
    assert expected == Credo.Config.read_or_default("/tmp/")
  end
end
