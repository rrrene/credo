defmodule Credo.Check.Design.RedundantConfigCommentsTest do
  use Credo.Test.Case

  alias Credo.CLI.Task.PrepareChecksToRun
  alias Credo.Execution

  @described_check Credo.Check.Design.RedundantConfigComments

  @filename "lib/credo_sample_module.ex"

  defp run_check_with_exec(%Credo.SourceFile{} = source_file, described_check, params, exec) do
    source_files = List.wrap(source_file)
    exec = PrepareChecksToRun.set_config_comments(exec, source_files)

    run_check(source_files, described_check, params, exec)
  end

  setup do
    [exec: Execution.build()]
  end

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    ~S'''
    defmodule CredoSampleModule do
      # credo:disable-for-this-file Credo.Check.Readability.ModuleAttributeNames
      @someFoobar false
    end
    '''
    |> to_source_file(@filename)
    |> run_check(@described_check, [])
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation when using # credo:disable-for-this-file", %{exec: exec} do
    ~S'''
    defmodule CredoSampleModule do
      # credo:disable-for-this-file Credo.Check.Readability.ModuleAttributeNames
      @some_foobar false
    end
    '''
    |> to_source_file(@filename)
    |> run_check_with_exec(@described_check, [], exec)
    |> assert_issue(%{trigger: "# credo:", line_no: 2})
  end

  test "it should report a violation when using # credo:disable-for-next-line", %{exec: exec} do
    ~S'''
    defmodule CredoSampleModule do
      # credo:disable-for-next-line Credo.Check.Readability.ModuleAttributeNames
      @some_foobar false
    end
    '''
    |> to_source_file(@filename)
    |> run_check_with_exec(@described_check, [], exec)
    |> assert_issue()
  end

  test "it should report a violation when using # credo:disable-for-previous-line", %{exec: exec} do
    ~S'''
    defmodule CredoSampleModule do

      @some_foobar false
      # credo:disable-for-previous-line Credo.Check.Readability.ModuleAttributeNames
    end
    '''
    |> to_source_file(@filename)
    |> run_check_with_exec(@described_check, [], exec)
    |> assert_issue()
  end

  test "it should report a violation when using # credo:disable-for-lines:3", %{exec: exec} do
    ~S'''
    defmodule CredoSampleModule do
      # credo:disable-for-lines:3 Credo.Check.Readability.ModuleAttributeNames
      @some_thing_else true
      @some_foobar false
    end
    '''
    |> to_source_file(@filename)
    |> run_check_with_exec(@described_check, [], exec)
    |> assert_issue()
  end
end
