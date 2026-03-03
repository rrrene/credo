defmodule Credo.Check.RunnerTest do
  use ExUnit.Case, async: true

  alias Credo.Check.Runner
  alias Credo.Execution
  alias Credo.Execution.ExecutionSourceFiles
  alias Credo.SourceFile

  defmodule CollectFilenamesCheck do
    def scheduled_in_group, do: 1

    def param_defaults do
      [
        files: %{
          included: nil,
          excluded: []
        }
      ]
    end

    def run_on_all_source_files(_exec, source_files, params) do
      filenames = Enum.map(source_files, & &1.filename)
      send(params[:test_pid], {:checked_files, filenames})
      :ok
    end
  end

  describe "files pattern filtering" do
    test "passes all files when no pattern is configured", %{test_pid: test_pid} do
      foo = Path.expand("test/fixtures/example_code/foo.ex")
      clean = Path.expand("test/fixtures/example_code/clean.ex")

      source_files = [
        %SourceFile{filename: foo},
        %SourceFile{filename: clean}
      ]

      :ok =
        run_checks(Execution.build(), source_files, [
          {CollectFilenamesCheck, [test_pid: test_pid]}
        ])

      assert_receive {:checked_files, [^foo, ^clean]}
    end

    test "passes matching files to the check", %{test_pid: test_pid} do
      foo = Path.expand("test/fixtures/example_code/foo.ex")
      config = Path.expand("test/fixtures/custom-config.exs")

      source_files = [
        %SourceFile{filename: foo},
        %SourceFile{filename: config}
      ]

      :ok =
        run_checks(Execution.build(), source_files, [
          {CollectFilenamesCheck, [files: %{included: ["test/fixtures/**/*.ex"], excluded: []}, test_pid: test_pid]}
        ])

      assert_receive {:checked_files, [^foo]}
    end

    test "passes no files when none match", %{test_pid: test_pid} do
      source_files = [
        %SourceFile{filename: Path.expand("test/fixtures/custom-config.exs")}
      ]

      :ok =
        run_checks(Execution.build(), source_files, [
          {CollectFilenamesCheck, [files: %{included: ["test/fixtures/**/*.ex"], excluded: []}, test_pid: test_pid]}
        ])

      assert_receive {:checked_files, []}
    end

    test "excludes files matching files.excluded", %{test_pid: test_pid} do
      foo = Path.expand("test/fixtures/example_code/foo.ex")
      clean = Path.expand("test/fixtures/example_code/clean.ex")

      source_files = [
        %SourceFile{filename: foo},
        %SourceFile{filename: clean}
      ]

      :ok =
        run_checks(Execution.build(), source_files, [
          {CollectFilenamesCheck, [files: %{included: ["test/fixtures/**/*.ex"], excluded: ["**/clean.ex"]}, test_pid: test_pid]}
        ])

      assert_receive {:checked_files, [^foo]}
    end

    test "excludes files when only files.excluded is configured", %{test_pid: test_pid} do
      foo = Path.expand("test/fixtures/example_code/foo.ex")
      clean = Path.expand("test/fixtures/example_code/clean.ex")

      source_files = [
        %SourceFile{filename: foo},
        %SourceFile{filename: clean}
      ]

      :ok =
        run_checks(Execution.build(), source_files, [
          {CollectFilenamesCheck, [files: %{included: nil, excluded: ["**/clean.ex"]}, test_pid: test_pid]}
        ])

      assert_receive {:checked_files, [^foo]}
    end
  end

  describe "stdin filtering" do
    test "applies file pattern filtering when reading from stdin", %{test_pid: test_pid} do
      source_files = [%SourceFile{filename: "lib/foo.ex"}]

      :ok =
        Execution.build()
        |> Execution.put_config(:read_from_stdin, true)
        |> run_checks(source_files, [
          {CollectFilenamesCheck, [files: %{included: ["lib/**/*.ex"], excluded: []}, test_pid: test_pid]}
        ])

      assert_receive {:checked_files, ["lib/foo.ex"]}
    end

    test "skips file when it does not match pattern when reading from stdin", %{test_pid: test_pid} do
      source_files = [%SourceFile{filename: "stdin"}]

      :ok =
        Execution.build()
        |> Execution.put_config(:read_from_stdin, true)
        |> run_checks(source_files, [
          {CollectFilenamesCheck, [files: %{included: ["lib/**/*.ex"], excluded: []}, test_pid: test_pid]}
        ])

      assert_receive {:checked_files, []}
    end
  end

  describe "rerun filtering" do
    test "passes only the changed file to the check", %{test_pid: test_pid} do
      foo = Path.expand("lib/foo.ex")
      bar = Path.expand("lib/bar.ex")

      source_files = [
        %SourceFile{filename: foo},
        %SourceFile{filename: bar}
      ]

      :ok =
        run_checks(Execution.build(), source_files, [
          {CollectFilenamesCheck, [__rerun_files_that_changed__: [foo], test_pid: test_pid]}
        ])

      assert_receive {:checked_files, [^foo]}
    end

    test "passes no files when the changed file is not a known source file", %{test_pid: test_pid} do
      foo = Path.expand("lib/foo.ex")
      bar = Path.expand("lib/bar.ex")
      baz = Path.expand("lib/baz.ex")

      source_files = [
        %SourceFile{filename: foo},
        %SourceFile{filename: bar}
      ]

      :ok =
        run_checks(Execution.build(), source_files, [
          {CollectFilenamesCheck, [__rerun_files_that_changed__: [baz], test_pid: test_pid]}
        ])

      assert_receive {:checked_files, []}
    end
  end

  defp run_checks(exec, source_files, enabled_checks) do
    exec =
      exec
      |> Map.update!(:cli_options, &Map.put(&1, :path, "."))
      |> Execution.put_config(:checks, %{enabled: enabled_checks, disabled: []})

    ExecutionSourceFiles.put(exec, source_files)
    Runner.run(source_files, exec)
  end
end
