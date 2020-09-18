defmodule Credo.PluginTest do
  use Credo.Test.Case, async: false

  @integration_path "test/fixtures/example_plugin_integration"

  alias Credo.Execution

  Code.require_file("test/fixtures/example_plugin_integration/plugin/example_plugin.ex")

  test "it should use ExamplePlugin's default config" do
    File.cd!(@integration_path, fn ->
      exec = Credo.run(["example", "--config-file", ".credo.exs"])

      {checks, _only_matching, _ignore_matching} = Execution.checks(exec)

      assert Enum.member?(checks, {Credo.Check.Readability.LargeNumbers, false})
    end)
  end

  test "it should run example command when example command is given" do
    exec = Credo.run([@integration_path, "example"])

    assert "Hello World!" == Execution.get_assign(exec, "example_plugin.hello")
  end

  test "it should run example command as default command" do
    exec = Credo.run([@integration_path])

    assert "Hello World!" == Execution.get_assign(exec, "example_plugin.hello")
  end

  test "it should accept --world CLI switch" do
    exec = Credo.run([@integration_path, "--world", "mars"])

    assert "Hello MARS!" == Execution.get_assign(exec, "example_plugin.hello")
  end

  test "it should accept -W CLI switch" do
    exec = Credo.run([@integration_path, "-W", "mars"])

    assert "Hello MARS!" == Execution.get_assign(exec, "example_plugin.hello")
  end
end
