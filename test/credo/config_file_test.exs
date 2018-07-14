defmodule Credo.ConfigFileTest do
  use ExUnit.Case

  alias Credo.ConfigFile

  def assert_sorted_equality(%ConfigFile{files: files1, checks: checks1}, %ConfigFile{
        files: files2,
        checks: checks2
      }) do
    assert files1 == files2
    assert_sorted_equality(checks1, checks2)
  end

  def assert_sorted_equality(checks1, checks2) do
    config1_sorted = checks1 |> Enum.sort()
    config2_sorted = checks2 |> Enum.sort()
    assert config1_sorted == config2_sorted
  end

  @default_config %ConfigFile{
    files: %{
      included: ["lib/", "src/", "web/"],
      excluded: []
    },
    checks: [
      {Credo.Check.Consistency.ExceptionNames},
      {Credo.Check.Consistency.LineEndings},
      {Credo.Check.Consistency.Tabs}
    ]
  }
  @example_config %ConfigFile{
    checks: [
      {Credo.Check.Design.AliasUsage},
      {Credo.Check.Design.TagFIXME},
      {Credo.Check.Design.TagTODO}
    ]
  }
  @example_config2 %ConfigFile{
    files: %{
      excluded: ["lib/**/*_test.exs"]
    },
    checks: [
      {Credo.Check.Consistency.ExceptionNames},
      {Credo.Check.Consistency.LineEndings},
      {Credo.Check.Consistency.Tabs}
    ]
  }

  test "the truth" do
    expected = %ConfigFile{
      files: %{
        included: ["lib/", "src/", "web/"],
        excluded: []
      },
      checks: [
        {Credo.Check.Consistency.ExceptionNames, []},
        {Credo.Check.Consistency.LineEndings, []},
        {Credo.Check.Consistency.Tabs, []},
        {Credo.Check.Design.AliasUsage, []},
        {Credo.Check.Design.TagFIXME, []},
        {Credo.Check.Design.TagTODO, []}
      ]
    }

    assert_sorted_equality(
      expected,
      ConfigFile.merge(@default_config, @example_config)
    )
  end

  test "merge works 2" do
    expected = %ConfigFile{
      files: %{
        included: ["lib/", "src/", "web/"],
        excluded: ["lib/**/*_test.exs"]
      },
      checks: [
        {Credo.Check.Consistency.ExceptionNames, []},
        {Credo.Check.Consistency.LineEndings, []},
        {Credo.Check.Consistency.Tabs, []}
      ]
    }

    assert_sorted_equality(
      expected,
      ConfigFile.merge(@default_config, @example_config2)
    )
  end

  test "merge works in the other direction, overwriting files[:excluded]" do
    expected = %ConfigFile{
      files: %{
        included: ["lib/", "src/", "web/"],
        excluded: []
      },
      checks: [
        {Credo.Check.Consistency.ExceptionNames, []},
        {Credo.Check.Consistency.LineEndings, []},
        {Credo.Check.Consistency.Tabs, []}
      ]
    }

    assert_sorted_equality(
      expected,
      ConfigFile.merge(@example_config2, @default_config)
    )
  end

  test "merge works with list" do
    expected = %ConfigFile{
      files: %{
        included: ["lib/", "src/", "web/"],
        excluded: ["lib/**/*_test.exs"]
      },
      checks: [
        {Credo.Check.Consistency.ExceptionNames, []},
        {Credo.Check.Consistency.LineEndings, []},
        {Credo.Check.Consistency.Tabs, []},
        {Credo.Check.Design.AliasUsage, []},
        {Credo.Check.Design.TagFIXME, []},
        {Credo.Check.Design.TagTODO, []}
      ]
    }

    assert_sorted_equality(
      expected,
      ConfigFile.merge([@default_config, @example_config2, @example_config])
    )
  end

  test "merge_checks works" do
    base = %ConfigFile{
      checks: [
        {Credo.Check.Consistency.ExceptionNames, []},
        {Credo.Check.Consistency.LineEndings, []},
        {Credo.Check.Consistency.Tabs, []}
      ]
    }

    other = %ConfigFile{
      checks: [
        {Credo.Check.Design.AliasUsage, []},
        {Credo.Check.Design.TagFIXME, []},
        {Credo.Check.Design.TagTODO, []},
        {Credo.Check.Consistency.Tabs, false}
      ]
    }

    expected = [
      {Credo.Check.Consistency.ExceptionNames, []},
      {Credo.Check.Consistency.LineEndings, []},
      {Credo.Check.Design.AliasUsage, []},
      {Credo.Check.Design.TagFIXME, []},
      {Credo.Check.Design.TagTODO, []},
      {Credo.Check.Consistency.Tabs, false}
    ]

    assert_sorted_equality(expected, ConfigFile.merge_checks(base, other))
  end

  test "loads .credo.exs from ./config subdirs in ascending directories as well" do
    dirs = ConfigFile.relevant_directories(".")

    config_subdir_count =
      dirs
      |> Enum.filter(&String.ends_with?(&1, "config"))
      |> Enum.count()

    assert config_subdir_count > 1
  end

  test "loads custom config file and merges with default" do
    config_file = Path.join([File.cwd!(), "test", "fixtures", "custom-config.exs"])

    configs = ConfigFile.read_from_file_path(".", config_file)
    # from default
    assert(Enum.member?(configs.checks, {Credo.Check.Readability.ModuleNames, []}))

    # from custom file
    assert(Enum.member?(configs.checks, {Credo.Check.Readability.ModuleDoc, false}))
  end
end
