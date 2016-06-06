defmodule Credo.CheckForUpdatesTest do
  use Credo.TestHelper

  alias Credo.CheckForUpdates

  test "it should work as expected" do
    all_versions = ~w{0.1.0 0.1.1 0.1.2 0.2.0-beta1 0.2.0-beta2}
    assert CheckForUpdates.should_update?(all_versions, "0.1.0")
    refute CheckForUpdates.should_update?(all_versions, "0.1.2")
    assert CheckForUpdates.should_update?(all_versions, "0.2.0-beta1")
    refute CheckForUpdates.should_update?(all_versions, "0.2.0-beta2")
  end
end
