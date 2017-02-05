defmodule Credo.CLI.OptionsTest do
  use Credo.TestHelper
  alias Credo.CLI.Options

  defp parse(args) do
    Options.parse(args).switches
  end

  test "it should work" do
    args = String.split("--strict --version")
    expected = %{strict: true, version: true}
    assert expected == parse(args)
  end

  test "it should not work w/ a funny typo: cash/crash" do
    args = String.split("--cash-on-error --version")
    expected = %{version: true}
    assert expected == parse(args)
  end

  test "it should not work w/ a string given for a number" do
    args = String.split("--min-priority=abc --version")
    expected = %{version: true}
    assert expected == parse(args)
  end


end
