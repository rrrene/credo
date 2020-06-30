defmodule Credo.CLI.OptionsTest do
  use Credo.Test.Case
  alias Credo.CLI.Options

  @command_names ["cmd1", "cmd2", "cmd3"]
  @fixture_name "options"
  @switches [
    all_priorities: :boolean,
    all: :boolean,
    checks: :string,
    config_name: :string,
    config_file: :string,
    color: :boolean,
    crash_on_error: :boolean,
    debug: :boolean,
    mute_exit_status: :boolean,
    format: :string,
    help: :boolean,
    ignore_checks: :string,
    ignore: :string,
    min_priority: :string,
    only: :string,
    read_from_stdin: :boolean,
    strict: :boolean,
    verbose: :boolean,
    version: :boolean
  ]
  @aliases [
    a: :all,
    A: :all_priorities,
    c: :checks,
    C: :config_name,
    d: :debug,
    h: :help,
    i: :ignore_checks,
    v: :version
  ]

  doctest Credo.CLI.Options

  defp fixture_path(name) do
    Path.join([File.cwd!(), "test", "fixtures", name])
  end

  defp expand_path(name) do
    Path.join(Path.expand(fixture_path(@fixture_name)), name)
  end

  defp parse(args) do
    dir = fixture_path(@fixture_name)
    Options.parse(args, dir, @command_names, [], @switches, @aliases)
  end

  defp switches(args), do: parse(args).switches

  test "switches: it should work" do
    args = String.split("cmd1 --strict --version")
    expected = %{strict: true, version: true}

    assert expected == switches(args)
  end

  test "switches: it should not work w/ a funny typo: cash/crash" do
    args = String.split("--cash-on-error --version")
    expected = %{version: true}

    assert expected == switches(args)
  end

  test "switches: it should convert min_priority high to 10" do
    args = String.split("--min-priority=high --version")
    expected = %{version: true, min_priority: 10}

    assert expected == switches(args)
  end

  test "switches: it should not work w/ an arbitrary string given for a number" do
    args = String.split("--min-priority=abc --version")

    assert_raise RuntimeError, fn -> switches(args) end
  end

  test "switches: it should convert min_priority normal to 1" do
    args = String.split("--min-priority=normal --version")
    expected = %{version: true, min_priority: 1}

    assert expected == switches(args)
  end

  test "switches: it should convert min_priority low to -10" do
    args = String.split("--min-priority=low --version")
    expected = %{version: true, min_priority: -10}

    assert expected == switches(args)
  end

  test "switches: it should convert min_priority to integer" do
    args = String.split("--min-priority=-1234 --version")
    expected = %{version: true, min_priority: -1234}

    assert expected == switches(args)
  end

  test "switches: it should reject float min_priority" do
    args = String.split("--min-priority=-1234.12 --version")

    assert_raise RuntimeError, fn -> switches(args) end
  end

  test "command: it should work w/o command" do
    args = String.split("--strict --version")
    options = parse(args)
    assert is_nil(options.command)
  end

  test "command: it should work although folder with same name present" do
    args = String.split("cmd1 --strict --version")
    expected = "cmd1"
    assert expected == parse(args).command
  end

  test "unknown_args: it should work" do
    args = String.split("unknown_cmd --strict --version")
    options = parse(args)
    assert is_nil(options.command)
    assert expand_path("") == options.path
    assert ["unknown_cmd"] == options.args
  end

  test "path: it should work w/ folder named like command when trailing slash is given" do
    args = String.split("cmd1/ --strict --version")
    options = parse(args)
    assert is_nil(options.command)
    assert expand_path("cmd1/") == options.path
  end

  test "path: it should work w/ folder" do
    args = String.split("src --strict --version")
    options = parse(args)
    assert is_nil(options.command)
    assert expand_path("src") == options.path
  end

  test "path: it should work w/ file" do
    args = String.split("foo.ex --strict --version")
    options = parse(args)
    assert is_nil(options.command)
    assert expand_path("foo.ex") == options.path
  end

  test "path: it should work w/ glob" do
    args = String.split("src/**/*.ex --strict --version")
    options = parse(args)
    assert is_nil(options.command)
    assert "src/**/*.ex" == options.path
  end
end
