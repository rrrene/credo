defmodule Credo.CLI.Output.UITest do
  use Credo.TestHelper

  alias Credo.CLI.Output.UI

  test "it should break up a long line into two elements" do
    lines =
"""
These checks take a look at your code and ensure a consistent coding style. Using tabs or spaces? Both is fine, just don't mix them or Credo will tell you.
""" |> String.strip |> UI.wrap_at(80)
    expected = [
      "These checks take a look at your code and ensure a consistent coding style. ",
      "Using tabs or spaces? Both is fine, just don't mix them or Credo will tell you."
    ]
    assert expected == lines
  end

  test "it should NOT break up a single line into more than one element" do
    lines =
      "These checks take a look at your code and ensure a consistent coding style."
      |> UI.wrap_at(80)
    expected = [
      "These checks take a look at your code and ensure a consistent coding style.",
    ]
    assert expected == lines
  end
end
