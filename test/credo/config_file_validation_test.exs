defmodule Credo.ConfigFile.ValidateTest do
  use ExUnit.Case
  alias Credo.ConfigFile.Validate

  setup do
    path = ".credo_test.exs"
    file = """
      %{
        configs: [
          %{
            requires: ["not_a_file.ex"],
            checks: [
              {Credo.Check.Readability.AlsoNotACheck, priority: :low},
              {Credo.Check.Consistency.NotACheck},
              {Credo.Check.Readability.Semicolons}
            ]
          }
        ]
      }
    """
    File.write!(path, file)
    errors = Validate.all_files([path], fn(errors) -> errors end)
    File.rm!(path)
    {:ok, [errors: errors]}
  end

  test ".all_files/1 outputs nothing with a valid config file" do
    path = ".credo_test.exs"
    file = """
      %{
        configs: [
          %{
            name: "default",
            requires: [],
            checks: [{Credo.Check.Readability.ModuleNames}]
          }
        ]
      }
    """
    File.write!(path, file)
    assert ExUnit.CaptureIO.capture_io(fn -> Validate.all_files([path]) end) == ""
  end

  test ".all_files/1 warns when the `name` key is missing from a config file", %{errors: errors} do
    expected = "Missing `name` key in `.credo_test.exs`"
    assert Enum.any?(errors, fn({:error, reason}) -> reason =~ expected end)
  end

  test ".all_files/1 warns when at least one file in `includes` is not present", %{errors: errors} do
    expected = "`not_a_file.ex` is not a valid file path"
    assert Enum.any?(errors, fn({:error, reason}) -> reason =~ expected end)
  end

  test ".all_files/1 warns when at least one check in `checks` is not defined", %{errors: errors} do
    expected = "Credo.Check.Consistency.NotACheck on line 7 is not a valid check"
    assert Enum.any?(errors, fn({:error, reason}) -> reason =~ expected end)

    expected = "Credo.Check.Readability.AlsoNotACheck on line 6 is not a valid check"
    assert Enum.any?(errors, fn({:error, reason}) -> reason =~ expected end)
  end
end
