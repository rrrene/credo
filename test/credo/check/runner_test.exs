defmodule Credo.Check.RunnerTest do
  use ExUnit.Case, async: true

  alias Credo.Check.Runner
  alias Credo.Execution
  alias Credo.Execution.ExecutionSourceFiles
  alias Credo.SourceFile

  defmodule CollectFilenamesCheck do
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

  describe "read_from_stdin behaviour" do
    test "runs the check on the stdin file when it matches files.included", %{test_pid: test_pid} do
      filename = Path.expand("lib/foo.ex")
      source_file = %SourceFile{filename: filename}

      exec =
        ExecutionSourceFiles.start_server(%Execution{
          read_from_stdin: true,
          checks: %{
            enabled: [
              {CollectFilenamesCheck,
               [files: %{included: ["lib/**/*.ex"], excluded: []}, test_pid: test_pid]}
            ],
            disabled: []
          }
        })

      ExecutionSourceFiles.put(exec, [source_file])

      :ok = Runner.run([source_file], exec)

      assert_receive {:checked_files, [^filename]}
    end

    test "runs the check with no files when the stdin file does not match files.included",
         %{test_pid: test_pid} do
      filename = Path.expand("test/foo_test.exs")
      source_file = %SourceFile{filename: filename}

      exec =
        ExecutionSourceFiles.start_server(%Execution{
          read_from_stdin: true,
          checks: %{
            enabled: [
              {CollectFilenamesCheck,
               [files: %{included: ["lib/**/*.ex"], excluded: []}, test_pid: test_pid]}
            ],
            disabled: []
          }
        })

      ExecutionSourceFiles.put(exec, [source_file])

      :ok = Runner.run([source_file], exec)

      assert_receive {:checked_files, []}
    end
  end

  describe "watch / rerun behaviour" do
    test "runs the check only on the changed file", %{test_pid: test_pid} do
      foo = Path.expand("lib/foo.ex")
      bar = Path.expand("lib/bar.ex")

      source_files = [
        %SourceFile{filename: foo},
        %SourceFile{filename: bar}
      ]

      exec =
        ExecutionSourceFiles.start_server(%Execution{
          read_from_stdin: false,
          checks: %{
            enabled: [
              {CollectFilenamesCheck, [__rerun_files_that_changed__: [foo], test_pid: test_pid]}
            ],
            disabled: []
          }
        })

      ExecutionSourceFiles.put(exec, source_files)

      :ok = Runner.run(source_files, exec)

      assert_receive {:checked_files, [^foo]}
    end

    test "runs the check with no files when the changed file is not a known source file",
         %{test_pid: test_pid} do
      foo = Path.expand("lib/foo.ex")
      bar = Path.expand("lib/bar.ex")
      baz = Path.expand("lib/baz.ex")

      source_files = [
        %SourceFile{filename: foo},
        %SourceFile{filename: bar}
      ]

      exec =
        ExecutionSourceFiles.start_server(%Execution{
          read_from_stdin: false,
          checks: %{
            enabled: [
              {CollectFilenamesCheck, [__rerun_files_that_changed__: [baz], test_pid: test_pid]}
            ],
            disabled: []
          }
        })

      ExecutionSourceFiles.put(exec, source_files)

      :ok = Runner.run(source_files, exec)

      assert_receive {:checked_files, []}
    end
  end

  describe "files pattern filtering" do
    test "filters known files using files patterns from params", %{test_pid: test_pid} do
      dir = "test/fixtures/integration_test_config"
      filename = Path.expand(Path.join(dir, "lib/clean.ex"))
      source_file = %SourceFile{filename: filename}

      exec =
        ExecutionSourceFiles.start_server(%Execution{
          cli_options: %{path: dir},
          read_from_stdin: false,
          checks: %{
            enabled: [
              {CollectFilenamesCheck,
               [__files__: %{included: ["lib/*.ex"], excluded: []}, test_pid: test_pid]}
            ],
            disabled: []
          }
        })

      ExecutionSourceFiles.put(exec, [source_file])

      :ok = Runner.run([source_file], exec)

      assert_receive {:checked_files, [^filename]}
    end
  end
end
