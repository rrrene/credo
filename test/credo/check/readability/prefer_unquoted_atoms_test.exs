defmodule Credo.Check.Readability.PreferUnquotedAtomsTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.PreferUnquotedAtoms

  #
  # cases NOT raising issues
  #

  test "it should NOT report when using an unquoted atom" do
    ~S'''
    :unquoted_atom
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report when using an unquoted keyword identifier" do
    ~S'''
    [unquoted_atom: 1]
    %{unquoted_atom: 1}
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report when required to use a quoted atom" do
    ~S'''
    :"complex\#{atom}"
    :"complex atom"
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report when required to use a quoted keyword identifier" do
    ~S'''
    ["complex\#{atom}": 1, "complex atom": 2]
    %{"complex\#{atom}": 1, "complex atom": 2}
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #
end
