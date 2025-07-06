defmodule Credo.SourcesTest do
  use ExUnit.Case

  alias Credo.CLI.Options

  @moduletag slow: :disk_io

  @fixture_integration_test_config "test/fixtures/integration_test_config"

  test "it finds all files inside directories recursively" do
    exec = %Credo.Execution{
      cli_options: %Options{path: "."},
      files: %{excluded: [], included: ["lib/mix"]}
    }

    expected = [
      "lib/mix/tasks/credo.ex",
      "lib/mix/tasks/credo.gen.check.ex",
      "lib/mix/tasks/credo.gen.config.ex"
    ]

    files =
      exec
      |> Credo.Sources.find()
      |> Enum.map(& &1.filename)

    assert expected == files
  end

  test "it accepts glob patterns that expand to files" do
    exec = %Credo.Execution{
      cli_options: %Options{path: "."},
      files: %{excluded: [], included: ["lib/mix/**/*gen*.ex"]}
    }

    expected = [
      "lib/mix/tasks/credo.gen.check.ex",
      "lib/mix/tasks/credo.gen.config.ex"
    ]

    files =
      exec
      |> Credo.Sources.find()
      |> Enum.map(& &1.filename)

    assert expected == files
  end

  test "it accepts glob patterns that expand to directories" do
    exec = %Credo.Execution{
      cli_options: %Options{path: "."},
      files: %{excluded: [], included: ["lib/**/tasks/"]}
    }

    expected = [
      "lib/mix/tasks/credo.ex",
      "lib/mix/tasks/credo.gen.check.ex",
      "lib/mix/tasks/credo.gen.config.ex"
    ]

    files =
      exec
      |> Credo.Sources.find()
      |> Enum.map(& &1.filename)

    assert expected == files
  end

  test "it accepts full file paths" do
    full_paths = ["lib/credo.ex", "lib/mix/tasks/credo.ex"]

    exec = %Credo.Execution{
      cli_options: %Options{path: "."},
      files: %{excluded: [], included: full_paths}
    }

    files =
      exec
      |> Credo.Sources.find()
      |> Enum.map(& &1.filename)

    assert full_paths == files
  end

  test "it rejects duplicate paths" do
    paths = [
      "lib/mix/tasks/credo.ex",
      "lib/mix",
      "lib/mix/tasks/credo.gen.check.ex"
    ]

    exec = %Credo.Execution{
      cli_options: %Options{path: "."},
      files: %{excluded: [], included: paths}
    }

    expected = [
      "lib/mix/tasks/credo.ex",
      "lib/mix/tasks/credo.gen.check.ex",
      "lib/mix/tasks/credo.gen.config.ex"
    ]

    files =
      exec
      |> Credo.Sources.find()
      |> Enum.map(& &1.filename)

    assert expected == files
  end

  test "it reads and parses found source files" do
    exec = %Credo.Execution{
      cli_options: %Options{path: "."},
      files: %{excluded: [], included: ["lib/mix/tasks/credo.ex"]}
    }

    [%Credo.SourceFile{status: :valid}] = Credo.Sources.find(exec)
  end

  test "it excludes paths that match the `excluded` patterns" do
    exec = %Credo.Execution{
      cli_options: %Options{path: "."},
      files: %{excluded: [~r/chec/, ~r/conf/], included: ["lib/mix"]}
    }

    expected = ["lib/mix/tasks/credo.ex"]

    files =
      exec
      |> Credo.Sources.find()
      |> Enum.map(& &1.filename)

    assert expected == files
  end

  test "it excludes paths from the `excluded` directories" do
    exec = %Credo.Execution{
      cli_options: %Options{path: "."},
      files: %{excluded: ["lib/credo"], included: ["lib"]}
    }

    expected = [
      "lib/credo.ex",
      "lib/mix/tasks/credo.ex",
      "lib/mix/tasks/credo.gen.check.ex",
      "lib/mix/tasks/credo.gen.config.ex"
    ]

    files =
      exec
      |> Credo.Sources.find()
      |> Enum.map(& &1.filename)

    assert expected == files
  end

  test "it excludes paths that match the `excluded` file globs" do
    exec = %Credo.Execution{
      cli_options: %Options{path: "."},
      files: %{excluded: ["lib/**/*gen*.ex"], included: ["lib/mix"]}
    }

    expected = ["lib/mix/tasks/credo.ex"]

    files =
      exec
      |> Credo.Sources.find()
      |> Enum.map(& &1.filename)

    assert expected == files
  end

  test "it excludes paths that match the `excluded` directory globs" do
    exec = %Credo.Execution{
      cli_options: %Options{path: "."},
      files: %{excluded: ["lib/**/credo/"], included: ["lib"]}
    }

    expected = [
      "lib/credo.ex",
      "lib/mix/tasks/credo.ex",
      "lib/mix/tasks/credo.gen.check.ex",
      "lib/mix/tasks/credo.gen.config.ex"
    ]

    files =
      exec
      |> Credo.Sources.find()
      |> Enum.map(& &1.filename)

    assert expected == files
  end

  test "it find list of paths" do
    paths =
      ["lib/credo.ex", "lib/credo/cli.ex"]
      |> Enum.map(&Path.expand/1)

    expected = paths
    assert expected == Credo.Sources.find(paths)
  end

  test "it finds with empty list path" do
    path = []

    expected = []

    assert expected == Credo.Sources.find(path)
  end

  test "it finds with binary path" do
    path = "lib/*.ex"

    expected =
      ["lib/credo.ex"]
      |> Enum.map(&Path.expand/1)

    assert expected == Credo.Sources.find(path)
  end

  test "it does not break" do
    exec = %Credo.Execution{
      cli_options: %Options{path: "."},
      files: %{
        included: ["lib/", "src/", "web/", "apps/"],
        excluded: [
          ~r"/_build/",
          ~r"/deps/",
          "apps/foo/mix.exs",
          "apps/foo/test/",
          "apps/bar/mix.exs",
          "apps/bar/test/",
          "apps/baz/mix.exs",
          "apps/baz/test/",
          "apps/bat/test/",
          "apps/bat/mix.exs"
        ]
      }
    }

    files =
      exec
      |> Credo.Sources.find()
      |> Enum.map(& &1.filename)

    assert files |> Enum.count() > 0
  end

  test "it finds in dir with binary path" do
    dir = @fixture_integration_test_config

    expected =
      ["#{dir}/lib/clean.ex"]
      |> Enum.map(&Path.expand/1)

    assert expected == Credo.Sources.find_in_dir(dir, ["lib/*.ex"], [])
  end

  test "it finds in dir and excludes given files" do
    dir = @fixture_integration_test_config

    expected =
      ["#{dir}/lib/clean/clean_redux.ex", "#{dir}/lib/clean/dirty.ex"]
      |> Enum.map(&Path.expand/1)

    assert expected == Credo.Sources.find_in_dir(dir, ["lib/**/*.ex"], ["lib/clean.ex"])
  end

  test "it finds in dir and excludes given files /2" do
    dir = @fixture_integration_test_config

    expected =
      ["#{dir}/lib/clean/clean_redux.ex"]
      |> Enum.map(&Path.expand/1)

    assert expected == Credo.Sources.find_in_dir(dir, [], ["lib/clean.ex", "lib/clean/dirty.ex"])
  end

  test "it finds in dir and includes given files" do
    dir = @fixture_integration_test_config

    expected =
      ["#{dir}/lib/clean.ex"]
      |> Enum.map(&Path.expand/1)

    assert expected == Credo.Sources.find_in_dir(dir, ["lib/clean.ex"], [])
  end

  test "it finds in dir and excludes given regex patterns" do
    dir = @fixture_integration_test_config

    expected = []

    assert expected == Credo.Sources.find_in_dir(dir, ["*.ex"], [~r/.ex$/])
  end

  test "it matches filenames given patterns" do
    assert Credo.Sources.filename_matches?("lib/credo/check/runner.ex", [
             "lib/credo/check/runner.ex"
           ])

    assert Credo.Sources.filename_matches?("lib/credo/check.ex", ["lib/*/check.ex"])
    assert Credo.Sources.filename_matches?("lib/credo/check/runner.ex", ["lib/**/runner.ex"])
    assert Credo.Sources.filename_matches?("lib/credo/check/runner.ex", ["lib/**/*.ex"])

    assert Credo.Sources.filename_matches?("lib/credo/check/foo.ex", ["lib/**/*.ex"])
    assert Credo.Sources.filename_matches?("lib/credo/check/foo.ex", [~r/.ex$/])

    refute Credo.Sources.filename_matches?("lib/credo/check/runner.ex", ["lib/*/runner.ex"])
    refute Credo.Sources.filename_matches?("lib/credo/check/runner.ex", ["*.exs"])
    refute Credo.Sources.filename_matches?("lib/credo/check/runner.ex", [~r/.exs$/])
  end

  test "it matches filenames given patterns /2" do
    assert Credo.Sources.filename_matches?("test/foo_test.ex", ["test/**/*_test.ex"])
    assert Credo.Sources.filename_matches?("test/foo/bar_test.ex", ["test/**/*_test.ex"])

    refute Credo.Sources.filename_matches?("test/foo_test.exs", ["test/**/*_test.ex"])
    refute Credo.Sources.filename_matches?("test/foo/bar_test.exs", ["test/**/*_test.ex"])
  end
end
