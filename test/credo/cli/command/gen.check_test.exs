defmodule Credo.CLI.Command.GenCheckTest do
  use Credo.Test.Case

  alias Credo.CLI.Command.GenCheck

  test "it should work" do
    expected = "SomeCustom42Check"

    assert expected == "../ecto/lib/some_custom_42_check.ex" |> GenCheck.check_name_for()

    assert expected == "lib/some_custom_42_check.ex" |> GenCheck.check_name_for()
  end
end
