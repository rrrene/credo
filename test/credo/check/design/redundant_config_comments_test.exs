defmodule Credo.Check.Design.RedundantConfigCommentsTest do
  use Credo.Test.Case

  alias Credo.Execution
  alias Credo.Issue

  @described_check Credo.Check.Design.RedundantConfigComments

  @filename "lib/credo_sample_module.ex"

  setup do
    issues =
      %Issue{
        filename: @filename,
        check: Credo.Check.Readability.ModuleAttributeNames,
        message: "some message",
        line_no: 3,
        column: 3,
        trigger: "@"
      }
      |> List.wrap()

    exec = Execution.put_issues(Execution.build(), issues)

    [exec: exec]
  end

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    exec = Execution.build()

    ~S'''
    defmodule CredoSampleModule do
      # credo:disable-for-this-file Credo.Check.Readability.ModuleAttributeNames
      @someFoobar false
    end
    '''
    |> to_source_file(@filename)
    |> run_check(@described_check, [], exec)
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
    |> run_check(@described_check, [], exec)
    |> assert_issue()
  end

  test "it should report a violation when using # credo:disable-for-next-line", %{exec: exec} do
    ~S'''
    defmodule CredoSampleModule do
      # credo:disable-for-next-line Credo.Check.Readability.ModuleAttributeNames
      @some_foobar false
    end
    '''
    |> to_source_file(@filename)
    |> run_check(@described_check, [], exec)
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
    |> run_check(@described_check, [], exec)
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
    |> run_check(@described_check, [], exec)
    |> assert_issue()
  end
end
