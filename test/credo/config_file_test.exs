defmodule Credo.ConfigFileTest do
  use ExUnit.Case

  alias Credo.ConfigFile

  def assert_sorted_equality(
        %ConfigFile{files: files1, checks: checks1},
        {:ok, config_file2}
      ) do
    %ConfigFile{files: files2, checks: checks2} = config_file2

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
  @example_config3 %ConfigFile{
    files: %{
      included: ["lib/**/*.exs"]
    },
    checks: [
      {Credo.Check.Consistency.ExceptionNames},
      {Credo.Check.Consistency.LineEndings},
      {Credo.Check.Consistency.Tabs}
    ]
  }

  test "merge works" do
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
      ConfigFile.merge({:ok, @default_config}, {:ok, @example_config})
    )
  end

  test "merge works /2" do
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
      ConfigFile.merge({:ok, @default_config}, {:ok, @example_config2})
    )
  end

  test "merge works /3" do
    expected = %ConfigFile{
      files: %{
        included: ["lib/**/*.exs"],
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
      ConfigFile.merge({:ok, @example_config2}, {:ok, @example_config3})
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
      ConfigFile.merge({:ok, @example_config2}, {:ok, @default_config})
    )
  end

  test "merge works in the other direction in reverse, NOT overwriting files[:excluded]" do
    expected = %ConfigFile{
      files: %{
        included: ["lib/**/*.exs"],
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
      ConfigFile.merge({:ok, @default_config}, {:ok, @example_config3})
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
      ConfigFile.merge([{:ok, @default_config}, {:ok, @example_config2}, {:ok, @example_config}])
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

  test "loads broken config file and return error tuple" do
    exec = Credo.Execution.build([])
    config_file = Path.join([File.cwd!(), "test", "fixtures", "custom-config.exs.malformed"])

    result = ConfigFile.read_from_file_path(exec, ".", config_file)

    expected = {:error, {:badconfig, config_file, 9, "syntax error before: ", "checks"}}

    assert expected == result
  end

  test "loads config file and sets defaults" do
    exec = Credo.Execution.build([])
    config_file = Path.join([File.cwd!(), "test", "fixtures", "custom-config.exs"])
    config_name = "empty-config"

    {:ok, result} = ConfigFile.read_from_file_path(exec, ".", config_file, config_name)

    assert is_boolean(result.color)
    assert is_boolean(result.strict)
    assert is_integer(result.parse_timeout)
    assert is_list(result.files.included)
    assert not Enum.empty?(result.files.included)
    assert is_list(result.files.excluded)
    assert is_list(result.checks)
  end
end
