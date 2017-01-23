defmodule Credo.CLI.SwitchesTest do
  use Credo.TestHelper
  alias Credo.Config
  alias Credo.CLI.Switches

  setup do
    config = %Config{files: nil, color: nil, checks: nil, skipped_checks: nil,
                     requires: [], min_priority: nil, help: nil, version: nil,
                     verbose: nil, strict: nil, all: nil, format: nil,
                     match_checks: nil, ignore_checks: nil, crash_on_error: nil,
                     check_for_updates: nil, read_from_stdin: nil,
                     lint_attribute_map: %{}}
    {:ok, [config: config]}
  end

  test "with empty switches does nothing", %{config: config} do
    switches = %{}
    output = Switches.parse_to_config(config, switches)
    assert config == output
  end

  test "sets basic properties based on given switches", %{config: config} do
    switches = %{all: true, color: true, help: true, verbose: true,
                  crash_on_error: true, read_from_stdin: true, version: true,
                  min_priority: -1, format: "oneline"}
    output = Switches.parse_to_config(config, switches)

    assert output.all == true
    assert output.color == true
    assert output.help == true
    assert output.verbose == true
    assert output.crash_on_error == true
    assert output.read_from_stdin == true
    assert output.version == true
    assert output.min_priority == -1
    assert output.format == "oneline"
  end

  test "sets strict a couple different ways", %{config: config} do
    switches1 = %{all_priorities: true}
    output1 = Switches.parse_to_config(config, switches1)
    assert output1.strict == true
    assert output1.all == true
    assert output1.min_priority == -99

    switches2 = %{strict: true}
    output2 = Switches.parse_to_config(config, switches2)
    assert output2.strict == true
    assert output2.all == true
    assert output2.min_priority == -99

    switches3 = %{strict: false}
    output3 = Switches.parse_to_config(config, switches3)
    assert output3.strict == false
    assert output3.all == false
    assert output3.min_priority == 0
  end

  test "sets `only` a couple different ways", %{config: config} do
    switches1 = %{only: "dogs,cats"}
    output1 = Switches.parse_to_config(config, switches1)
    assert output1.match_checks == ["dogs", "cats"]
    assert output1.strict == true
    assert output1.all == true
    assert output1.min_priority == -99

    switches2 = %{checks: "dogs,cats"}
    output2 = Switches.parse_to_config(config, switches2)
    assert output2.match_checks == ["dogs", "cats"]
    assert output2.strict == true
    assert output2.all == true
    assert output2.min_priority == -99
  end

  test "sets `ignore` a couple different ways", %{config: config} do
    switches1 = %{ignore: "dogs,cats"}
    output1 = Switches.parse_to_config(config, switches1)
    assert output1.ignore_checks == ["dogs", "cats"]

    switches2 = %{ignore_checks: "dogs,cats"}
    output2 = Switches.parse_to_config(config, switches2)
    assert output2.ignore_checks == ["dogs", "cats"]
  end
end
