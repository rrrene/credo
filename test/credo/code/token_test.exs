defmodule Credo.Code.TokenTest do
  use Credo.TestHelper

  alias Credo.Code.Token

  # Elixir >= 1.6.0
  if Version.match?(System.version(), ">= 1.6.0-rc") do
    test "token position" do
      source = "134 + 145"

      {:ok, tokens} =
        source
        |> Credo.Backports.String.to_charlist()
        |> :elixir_tokenizer.tokenize(1, [])

      expected = [
        {:int, {1, 1, 134}, '134'},
        {:dual_op, {1, 5, nil}, :+},
        {:int, {1, 7, 145}, '145'}
      ]

      assert expected == tokens

      expected_position = {1, 7, 10}

      assert expected_position == expected |> List.last() |> Token.position()
    end
  end

  # Elixir <= 1.5.x
  if Version.match?(System.version(), "< 1.6.0-rc") do
    test "token position" do
      source = "134 + 145"

      {:ok, 1, 10, tokens} =
        source
        |> Credo.Backports.String.to_charlist()
        |> :elixir_tokenizer.tokenize(1, [])

      expected = [
        {:number, {1, 1, 4}, 134},
        {:dual_op, {1, 5, 6}, :+},
        {:number, {1, 7, 10}, 145}
      ]

      assert expected == tokens

      expected_position = {1, 7, 10}

      assert expected_position == expected |> List.last() |> Token.position()
    end
  end
end
