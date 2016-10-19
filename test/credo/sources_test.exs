defmodule Credo.SourcesTest do
  use ExUnit.Case

  test "it finds all files inside directories recursively" do
    config = %Credo.Config{files: %{excluded: [], included: ["lib/mix"]}}

    expected = [
      "lib/mix/tasks/credo.ex",
      "lib/mix/tasks/credo.gen.check.ex",
      "lib/mix/tasks/credo.gen.config.ex"
    ]

    files = Credo.Sources.find(config) |> Enum.map(&(&1.filename))

    assert expected == files
  end

  test "it accepts glob patterns that expand to files" do
    config = %Credo.Config{files: %{excluded: [], included: ["lib/mix/**/*gen*.ex"]}}

    expected = [
      "lib/mix/tasks/credo.gen.check.ex",
      "lib/mix/tasks/credo.gen.config.ex"
    ]

    files = Credo.Sources.find(config) |> Enum.map(&(&1.filename))

    assert expected == files
  end

  test "it accepts glob patterns that expand to directories" do
    config = %Credo.Config{files: %{excluded: [], included: ["lib/**/tasks/"]}}

    expected = [
      "lib/mix/tasks/credo.ex",
      "lib/mix/tasks/credo.gen.check.ex",
      "lib/mix/tasks/credo.gen.config.ex"
    ]

    files = Credo.Sources.find(config) |> Enum.map(&(&1.filename))

    assert expected == files
  end

  test "it accepts full file paths" do
    full_paths = ["lib/credo.ex", "lib/mix/tasks/credo.ex"]
    config = %Credo.Config{files: %{excluded: [], included: full_paths}}

    files = Credo.Sources.find(config) |> Enum.map(&(&1.filename))

    assert full_paths == files
  end

  test "it rejects duplicate paths" do
    paths = ["lib/mix/tasks/credo.ex", "lib/mix", "lib/mix/tasks/credo.gen.check.ex"]
    config = %Credo.Config{files: %{excluded: [], included: paths}}

    expected = [
      "lib/mix/tasks/credo.ex",
      "lib/mix/tasks/credo.gen.check.ex",
      "lib/mix/tasks/credo.gen.config.ex"
    ]

    files = Credo.Sources.find(config) |> Enum.map(&(&1.filename))

    assert expected == files
  end

  test "it reads and parses found source files" do
    config = %Credo.Config{files: %{excluded: [], included: ["lib/mix/tasks/credo.ex"]}}

    [%Credo.SourceFile{ast: ast, valid?: true}] = Credo.Sources.find(config)

    assert ast != nil
  end

  test "it excludes paths that match the `excluded` patterns" do
    config = %Credo.Config{files: %{excluded: [~r/chec/, ~r/conf/], included: ["lib/mix"]}}

    expected = ["lib/mix/tasks/credo.ex"]

    files = Credo.Sources.find(config) |> Enum.map(&(&1.filename))

    assert expected == files
  end

  test "it excludes paths from the `excluded` directories" do
    config = %Credo.Config{files: %{excluded: ["lib/credo"], included: ["lib"]}}

    expected = [
      "lib/credo.ex",
      "lib/mix/tasks/credo.ex",
      "lib/mix/tasks/credo.gen.check.ex",
      "lib/mix/tasks/credo.gen.config.ex"
    ]

    files = Credo.Sources.find(config) |> Enum.map(&(&1.filename))

    assert expected == files
  end

  test "it excludes paths that match the `excluded` file globs" do
    config = %Credo.Config{files: %{excluded: ["lib/**/*gen*.ex"], included: ["lib/mix"]}}

    expected = ["lib/mix/tasks/credo.ex"]

    files = Credo.Sources.find(config) |> Enum.map(&(&1.filename))

    assert expected == files
  end

  test "it excludes paths that match the `excluded` directory globs" do
    config = %Credo.Config{files: %{excluded: ["lib/**/credo/"], included: ["lib"]}}

    expected = [
      "lib/credo.ex",
      "lib/mix/tasks/credo.ex",
      "lib/mix/tasks/credo.gen.check.ex",
      "lib/mix/tasks/credo.gen.config.ex"
    ]

    files = Credo.Sources.find(config) |> Enum.map(&(&1.filename))

    assert expected == files
  end

  test "it find list of pathes" do
    pathes =
      ["lib/credo.ex", "lib/credo/cli.ex"]
      |> Enum.map(&Path.expand/1)

    expected = pathes
    assert expected == Credo.Sources.find(pathes)
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
    config = %Credo.Config{files: %{included: ["lib/", "src/", "web/", "apps/"],
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
          "apps/bat/mix.exs",
        ]
        }}

    files = Credo.Sources.find(config) |> Enum.map(&(&1.filename))

    assert files |> Enum.count > 0
  end
end
