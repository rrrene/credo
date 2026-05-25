defmodule Credo.Check.AllLoadedChecksTest do
  use ExUnit.Case, async: true

  # `all_loaded_checks/0` used to source its result from `:code.all_loaded/0`,
  # so any check module nothing had yet referenced was silently missing —
  # which is exactly what made `MissingCheckInConfig` fail to flag unused
  # checks (#1278). The fix sources credo's own checks from the curated
  # `standard_checks/0` list and supplements with check modules discovered
  # via `:application.get_key/2` on every other loaded application, so the
  # result is independent of which modules happen to be loaded.

  test "returns every standard credo check regardless of load order" do
    all = Credo.Check.all_loaded_checks()
    missing = Credo.Check.standard_checks() -- all

    assert missing == [],
           "expected all standard checks to be included in `all_loaded_checks/0`, " <>
             "but these were missing: #{inspect(missing)}"
  end

  test "result contains no duplicates" do
    all = Credo.Check.all_loaded_checks()
    assert all == Enum.uniq(all)
  end
end
