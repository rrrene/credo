defmodule Credo.OutdatedTest do
  use Credo.TestHelper

  alias Credo.Outdated

  test "it should work as expected" do
    all_versions = ~w{0.1.0 0.1.1 0.1.2 0.2.0-beta1 0.2.0-beta2}
    assert Outdated.should_update?(all_versions, "0.1.0")
    refute Outdated.should_update?(all_versions, "0.1.2")
    assert Outdated.should_update?(all_versions, "0.2.0-beta1")
    refute Outdated.should_update?(all_versions, "0.2.0-beta2")
  end
end
