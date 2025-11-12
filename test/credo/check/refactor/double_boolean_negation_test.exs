defmodule Credo.Check.Refactor.DoubleBooleanNegationTest do
  use Credo.Test.Case

  @described_check Credo.Check.Refactor.DoubleBooleanNegation

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    ~S'''
    !true
    not true
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    ~S'''
    !!true
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "!!"
    end)
  end

  test "it should report a violation just once" do
    ~S'''
    !!!true
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "!!"
    end)
  end

  test "it should report a violation twice" do
    ~S'''
    !!!!true
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues()
  end

  test "it should report a violation 2" do
    ~S'''
    not not true
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "not not"
    end)
  end

  test "it should report mixed violation '! not'" do
    ~S'''
    ! not true
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "! not"
    end)
  end

  test "it should report mixed violation 'not !'" do
    ~S'''
    not ! true
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "not !"
    end)
  end
end
