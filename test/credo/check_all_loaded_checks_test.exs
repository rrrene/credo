defmodule Credo.Check.AllLoadedChecksTest do
  use ExUnit.Case, async: false

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

  test "discovers external checks from the application manifest without loading them" do
    unique = System.unique_integer([:positive])
    app = :"credo_check_fixture_#{unique}"
    module = Module.concat([CredoCheckFixture, "Check#{unique}"])
    tmp_dir = Path.join(System.tmp_dir!(), "credo_check_fixture_#{unique}")
    ebin_dir = Path.join(tmp_dir, "ebin")

    File.mkdir_p!(ebin_dir)

    forms = [
      {:attribute, 1, :module, module},
      {:attribute, 1, :behaviour, Credo.Check}
    ]

    {:ok, ^module, beam} = :compile.forms(forms, [:binary])

    File.write!(Path.join(ebin_dir, "#{module}.beam"), beam)

    app_spec = {:application, app, applications: [:kernel, :stdlib], modules: [module]}
    File.write!(Path.join(ebin_dir, "#{app}.app"), :io_lib.format(~c"~p.~n", [app_spec]))

    :code.add_patha(String.to_charlist(ebin_dir))
    assert :ok = Application.load(app)

    on_exit(fn ->
      Application.unload(app)
      :code.del_path(String.to_charlist(ebin_dir))
      File.rm_rf!(tmp_dir)
    end)

    assert :code.is_loaded(module) == false
    refute module in Credo.Code.loaded_modules_implementing(Credo.Check)
    assert module in Credo.Check.all_loaded_checks()
    assert :code.is_loaded(module) == false
  end
end
