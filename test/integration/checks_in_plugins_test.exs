defmodule Credo.ChecksInPluginsTest do
  use Credo.Test.Case, async: false

  alias Credo.Test.IntegrationTest

  @integration_path "test/fixtures/example_checks_in_config"

  Code.require_file("test/fixtures/example_checks_in_config/plugin/check_plugin.ex")

  test "it should use ExamplePlugin's default config and find the mentioned check" do
    File.cd!(@integration_path, fn ->
      exec = IntegrationTest.run(["info", "--config-file", ".credo.exs", "--debug"])

      assert Enum.member?(Credo.Check.mentioned_checks(exec), ExampleCheckPlugin.MyCustomCheck)
    end)
  end
end
