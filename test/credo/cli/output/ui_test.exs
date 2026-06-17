defmodule Credo.CLI.Output.UITest do
  use Credo.Test.Case

  alias Credo.CLI.Output.UI

  doctest Credo.CLI.Output.UI

  test "it should break up a long line into two elements" do
    lines =
      """
      These checks take a look at your code and ensure a consistent coding style. Using tabs or spaces? Both is fine, just don't mix them or Credo will tell you.
      """
      |> String.trim()
      |> UI.wrap_at(80)

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
      "These checks take a look at your code and ensure a consistent coding style."
    ]

    assert expected == lines
  end

  test "it should keep each line break on its own element so callers can write them" do
    lines =
      "First line of the message.\nSecond line of the message."
      |> UI.wrap_at(80)

    expected = [
      "First line of the message.\n",
      "Second line of the message."
    ]

    assert expected == lines
  end

  test "it should keep a blank line as its own element" do
    lines =
      "First paragraph.\n\nSecond paragraph."
      |> UI.wrap_at(80)

    expected = [
      "First paragraph.\n",
      "\n",
      "Second paragraph."
    ]

    assert expected == lines
  end

  test "with_trailing_newline should append a newline to plain content" do
    assert ["Plain wrapped line", "\n"] == UI.with_trailing_newline("Plain wrapped line")
  end

  test "with_trailing_newline should not double a newline already present in the final chunk" do
    line = ["First line of the message.\n"]

    assert line == UI.with_trailing_newline(line)
  end

  test "with_trailing_newline should keep a blank line as a single line break" do
    line = ["\n"]

    assert line == UI.with_trailing_newline(line)
  end

  test "it should be able to break up a line including unicode characters" do
    lines =
      "あいうえ"
      |> UI.wrap_at(2)

    expected = [
      "あい",
      "うえ"
    ]

    assert expected == lines
  end

  test "truncate when max_length > ellipsis length and truncation required" do
    # Even if the ellipsis is longer than the max length we should not
    # truncate the ellipsis so the human reader doesn't have to figure out
    # that the "." they're seeing is part of a truncated "..."
    assert UI.truncate("hello", 1, "...") == "..."
  end

  test "truncate with max_length of 0" do
    assert UI.truncate("hello", 0) == ""
  end

  test "truncate with max_length < 0" do
    assert UI.truncate("hello", -5) == ""
  end
end
