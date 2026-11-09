defmodule Credo.Check.RunnerTest do
  # `Credo.run/1` mutates global state (e.g. `Credo.CLI.Output.Shell`), so this must not run concurrently with other tests
  use Credo.Test.Case, async: false

  alias Credo.Test.IntegrationTest

  @moduletag slow: :disk_io

  # Both files in this fixture lack a `@moduledoc`, but the fixture's config
  # excludes `lib/excluded.ex` from `Credo.Check.Readability.ModuleDoc`.
  @fixture "test/fixtures/check_files_excluded_only"

  test "it applies a check's `files: %{excluded: ...}` param when run on a subdirectory (like an umbrella app)" do
    # Running on a subdirectory of the cwd means the source files' names (relative to the cwd)
    # differ from their paths relative to the working dir.
    exec = IntegrationTest.run([@fixture])

    filenames =
      exec
      |> Credo.Execution.get_issues()
      |> Enum.map(&{&1.check, Path.relative_to_cwd(&1.filename)})

    assert [{Credo.Check.Readability.ModuleDoc, Path.join(@fixture, "lib/included.ex")}] == filenames
  end
end
