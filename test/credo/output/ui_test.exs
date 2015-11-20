defmodule Credo.CLI.Output.UITest do
  use Credo.TestHelper

  alias Credo.CLI.Output.UI

  test "it should NOT report expected code" do
    lines =
"""
These checks take a look at your code and ensure a consistent coding style. Using tabs or spaces? Both is fine, just don't mix them or Credo will tell you.
""" |> UI.wrap_at(80)
    expected = [
      "These checks take a look at your code and ensure a consistent coding style.",
      "Using tabs or spaces? Both is fine, just don't mix them or Credo will tell you."
    ]
    assert expected == lines
  end
end
