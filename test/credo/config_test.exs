defmodule Credo.ConfigTest do
  use ExUnit.Case

  alias Credo.Config

  @default_config %Config{
                    files: %{
                      included: ["lib/", "src/", "web/"],
                      excluded: []
                    },
                    checks: [
                      {Credo.Check.Consistency.ExceptionNames},
                      {Credo.Check.Consistency.LineEndings},
                      {Credo.Check.Consistency.Tabs},
                    ]
                  }
  @example_config %Config{
                    checks: [
                      {Credo.Check.Design.AliasUsage},
                      {Credo.Check.Design.TagFIXME},
                      {Credo.Check.Design.TagTODO},
                    ]
                  }
  @example_config2 %Config{
                    files: %{
                      excluded: ["lib/**/*_test.exs"]
                    },
                    checks: [
                      {Credo.Check.Consistency.ExceptionNames},
                      {Credo.Check.Consistency.LineEndings},
                      {Credo.Check.Consistency.Tabs},
                    ]
                  }


  test "the truth" do
    expected = %Config{
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
                      {Credo.Check.Design.TagTODO, []},
                    ]
                  }
    assert expected == Config.merge(@default_config, @example_config)
  end

  test "merge works 2" do
    expected = %Config{
                    files: %{
                      included: ["lib/", "src/", "web/"],
                      excluded: ["lib/**/*_test.exs"]
                    },
                    checks: [
                      {Credo.Check.Consistency.ExceptionNames, []},
                      {Credo.Check.Consistency.LineEndings, []},
                      {Credo.Check.Consistency.Tabs, []},
                    ]
                  }
    assert expected == Config.merge(@default_config, @example_config2)
  end

  test "merge works in the other direction, overwriting files[:excluded]" do
    expected = %Config{
                    files: %{
                      included: ["lib/", "src/", "web/"],
                      excluded: []
                    },
                    checks: [
                      {Credo.Check.Consistency.ExceptionNames, []},
                      {Credo.Check.Consistency.LineEndings, []},
                      {Credo.Check.Consistency.Tabs, []},
                    ]
                  }
    assert expected == Config.merge(@example_config2, @default_config)
  end

  test "merge works with list" do
    expected = %Config{
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
                      {Credo.Check.Design.TagTODO, []},
                    ]
                  }
    assert expected == Config.merge([@default_config, @example_config2, @example_config])
  end

  test "merge_checks works" do
    base =
      %Config{
        checks: [
          {Credo.Check.Consistency.ExceptionNames, []},
          {Credo.Check.Consistency.LineEndings, []},
          {Credo.Check.Consistency.Tabs, []},
        ]
      }
    other =
      %Config{
        checks: [
          {Credo.Check.Design.AliasUsage, []},
          {Credo.Check.Design.TagFIXME, []},
          {Credo.Check.Design.TagTODO, []},
          {Credo.Check.Consistency.Tabs, false},
        ]
      }
    expected =
      [
        {Credo.Check.Consistency.ExceptionNames, []},
        {Credo.Check.Consistency.LineEndings, []},
        {Credo.Check.Design.AliasUsage, []},
        {Credo.Check.Design.TagFIXME, []},
        {Credo.Check.Design.TagTODO, []},
        {Credo.Check.Consistency.Tabs, false},
      ]
    assert expected == Config.merge_checks(base, other)
  end

  test "loads .credo.exs from ./config subdirs in ascending directories as well" do
    dirs = Config.relevant_directories(".")
    config_subdir_count =
      dirs
      |> Enum.filter(&(String.ends_with?(&1, "config")))
      |> Enum.count

    assert config_subdir_count > 1
  end
end
