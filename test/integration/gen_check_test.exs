defmodule Credo.GenCheckTest do
  use Credo.Test.Case

  @moduletag slow: :integration

  test "it should generate a new check" do
    exec = Credo.run(["gen.check", "tmp/lib/my_first_credo_check.ex"])

    assert exec.cli_options.command == "gen.check"
  end

  test "it should show help on generating a new check" do
    exec = Credo.run(["gen.check", "--help"])

    assert exec.cli_options.command == "gen.check"
  end
end
