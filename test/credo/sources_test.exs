defmodule Credo.SourcesTest do
  use ExUnit.Case

  alias Credo.CLI.Options
  alias Credo.Execution

  @moduletag slow: :disk_io

  @fixture_integration_test_config "test/fixtures/integration_test_config"

  setup do
    [exec: %Execution{config: %Execution.RuntimeConfig{}, private: %Execution.Private{}}]
  end

  test "it finds all files inside directories recursively", %{exec: exec} do
    exec = %{exec | cli_options: %Options{path: "."}, config: %{files: %{excluded: [], included: ["lib/mix"]}}}

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

  test "it accepts glob patterns that expand to files", %{exec: exec} do
    exec = %{
      exec
      | cli_options: %Options{path: "."},
        config: %{files: %{excluded: [], included: ["lib/mix/**/*gen*.ex"]}}
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

  test "it accepts glob patterns that expand to directories", %{exec: exec} do
    exec = %{
      exec
      | cli_options: %Options{path: "."},
        config: %{files: %{excluded: [], included: ["lib/**/tasks/"]}}
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

  test "it accepts full file paths", %{exec: exec} do
    full_paths = ["lib/credo.ex", "lib/mix/tasks/credo.ex"]

    exec = %{
      exec
      | cli_options: %Options{path: "."},
        config: %{files: %{excluded: [], included: full_paths}}
    }

    files =
      exec
      |> Credo.Sources.find()
      |> Enum.map(& &1.filename)

    assert full_paths == files
  end

  test "it rejects duplicate paths", %{exec: exec} do
    paths = [
      "lib/mix/tasks/credo.ex",
      "lib/mix",
      "lib/mix/tasks/credo.gen.check.ex"
    ]

    exec = %{
      exec
      | cli_options: %Options{path: "."},
        config: %{files: %{excluded: [], included: paths}}
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

  test "it reads and parses found source files", %{exec: exec} do
    exec = %{
      exec
      | cli_options: %Options{path: "."},
        config: %{files: %{excluded: [], included: ["lib/mix/tasks/credo.ex"]}}
    }

    [%Credo.SourceFile{status: :valid}] = Credo.Sources.find(exec)
  end

  test "it excludes paths that match the `excluded` patterns", %{exec: exec} do
    exec = %{
      exec
      | cli_options: %Options{path: "."},
        config: %{files: %{excluded: [~r/chec/, ~r/conf/], included: ["lib/mix"]}}
    }

    expected = ["lib/mix/tasks/credo.ex"]

    files =
      exec
      |> Credo.Sources.find()
      |> Enum.map(& &1.filename)

    assert expected == files
  end

  test "it excludes paths from the `excluded` directories", %{exec: exec} do
    exec = %{
      exec
      | cli_options: %Options{path: "."},
        config: %{files: %{excluded: ["lib/credo"], included: ["lib"]}}
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

  test "it excludes paths that match the `excluded` file globs", %{exec: exec} do
    exec = %{
      exec
      | cli_options: %Options{path: "."},
        config: %{files: %{excluded: ["lib/**/*gen*.ex"], included: ["lib/mix"]}}
    }

    expected = ["lib/mix/tasks/credo.ex"]

    files =
      exec
      |> Credo.Sources.find()
      |> Enum.map(& &1.filename)

    assert expected == files
  end

  test "it excludes paths that match the `excluded` directory globs", %{exec: exec} do
    exec = %{
      exec
      | cli_options: %Options{path: "."},
        config: %{files: %{excluded: ["lib/**/credo/"], included: ["lib"]}}
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

  test "it does not break", %{exec: exec} do
    exec = %{
      exec
      | cli_options: %Options{path: "."},
        config: %{
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

  describe "find_in_paths/4" do
    # this directory does not exist, so these tests also ensure that matching happens in memory
    @fake_dir "/credo_nonexistent_project"

    @fake_paths Enum.map(
                  [
                    "mix.exs",
                    "lib/app.ex",
                    "lib/app/worker.ex",
                    "lib/app/web/router.ex",
                    "lib/.hidden/secret.ex",
                    "test/test_helper.exs",
                    "test/app_test.exs",
                    "test/app/worker_test.exs",
                    "test/support/case.ex"
                  ],
                  &Path.join(@fake_dir, &1)
                )

    defp find_in_fake_paths(included, excluded, paths \\ @fake_paths) do
      paths
      |> Credo.Sources.find_in_paths(@fake_dir, included, excluded)
      |> Enum.map(&Path.relative_to(&1, @fake_dir))
    end

    test "it matches globs" do
      assert ["test/app/worker_test.exs", "test/app_test.exs"] == find_in_fake_paths(["test/**/*_test.exs"], [])
      assert ["lib/app.ex"] == find_in_fake_paths(["lib/*.ex"], [])
      assert ["lib/app/worker.ex", "test/app/worker_test.exs"] == find_in_fake_paths(["{lib,test}/app/*.{ex,exs}"], [])
      assert ["lib/app/worker.ex"] == find_in_fake_paths(["lib/app/w?rker.ex"], [])
      assert [] == find_in_fake_paths(["src/**/*.ex"], [])
    end

    test "it ignores paths starting with a dot when globbing, like Path.wildcard/1" do
      expected = ["lib/app.ex", "lib/app/web/router.ex", "lib/app/worker.ex"]
      assert expected == find_in_fake_paths(["lib/**/*.ex"], [])
      assert expected == find_in_fake_paths(["lib/"], [])
    end

    test "it expands directories" do
      assert ["lib/app/web/router.ex", "lib/app/worker.ex"] == find_in_fake_paths(["lib/app"], [])

      assert ["lib/app/web/router.ex", "lib/app/worker.ex", "test/support/case.ex"] ==
               find_in_fake_paths(["lib/app/", "test/support"], [])
    end

    test "it matches literal file paths" do
      assert ["lib/app/worker.ex"] == find_in_fake_paths(["lib/app/worker.ex"], [])
    end

    test "it does not return literal file paths that are not among the given paths" do
      assert [] == find_in_fake_paths(["lib/not_loaded.ex"], [])
      assert ["lib/app.ex"] == find_in_fake_paths(["lib/not_loaded.ex", "lib/app.ex"], [])
    end

    test "it normalizes the given paths" do
      unnormalized = Enum.map(["lib/./app.ex", "lib/app/../app/worker.ex", "test/"], &(@fake_dir <> "/" <> &1))
      normalized = Enum.map(["lib/app.ex", "lib/app/worker.ex", "test"], &Path.join(@fake_dir, &1))

      assert normalized == Credo.Sources.find_in_paths(unnormalized, @fake_dir, :all, [])
      assert ["lib/app.ex", "lib/app/worker.ex"] == find_in_fake_paths(["lib/"], [], unnormalized)
      assert ["lib/app/worker.ex"] == find_in_fake_paths(:all, ["lib/app.ex", "test"], unnormalized)
    end

    test "it excludes globs, directories and regexes" do
      assert ["test/app_test.exs", "test/test_helper.exs"] ==
               find_in_fake_paths(["test/"], ["test/app/", "test/**/*.ex"])

      assert ["test/app_test.exs"] == find_in_fake_paths(["test/"], [~r/helper|support|worker/])
    end

    test "it includes all paths by default" do
      assert [
               "lib/app.ex",
               "lib/app/web/router.ex",
               "lib/app/worker.ex",
               "mix.exs",
               "test/app/worker_test.exs",
               "test/app_test.exs",
               "test/test_helper.exs"
             ] == find_in_fake_paths([], ["test/support/case.ex"])
    end

    test "it includes every given path for :all" do
      paths = [Path.join(@fake_dir, "README.md") | @fake_paths]

      assert Enum.sort(paths) == Credo.Sources.find_in_paths(paths, @fake_dir, :all, [])

      assert [
               "README.md",
               "lib/.hidden/secret.ex",
               "lib/app.ex",
               "lib/app/worker.ex",
               "mix.exs"
             ] == find_in_fake_paths(:all, ["test/", ~r/router/], paths)
    end

    test "it ignores files on disk that are not among the given paths" do
      dir = @fixture_integration_test_config
      [clean_redux, dirty] = Enum.map(["lib/clean/clean_redux.ex", "lib/clean/dirty.ex"], &Path.expand(&1, dir))

      # Sanity check: both files exist and match on disk
      assert [clean_redux, dirty] == Credo.Sources.find_in_dir(dir, ["lib/clean/"], [])

      assert [dirty] == Credo.Sources.find_in_paths([dirty], dir, ["lib/clean/"], [])
      assert [dirty] == Credo.Sources.find_in_paths([dirty], dir, ["lib/**/*.ex"], [])
    end

    test "it returns the same files as find_in_dir/3 for files on disk" do
      dir = @fixture_integration_test_config
      paths = Credo.Sources.find_in_dir(dir, [], [])

      for {included, excluded} <- [
            {["lib/*.ex"], []},
            {["lib/**/*.ex"], ["lib/clean.ex"]},
            {[], ["lib/clean.ex", "lib/clean/dirty.ex"]},
            {["lib/"], [~r/dirty/]},
            {["*.ex"], [~r/.ex$/]}
          ] do
        assert Credo.Sources.find_in_dir(dir, included, excluded) ==
                 Credo.Sources.find_in_paths(paths, dir, included, excluded)
      end
    end
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
