defmodule Credo.Check.Readability.ImplTrueTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.ImplTrue

  #
  # cases NOT raising issues
  #

  test "it should NOT report @impl Behaviour" do
    ~S'''
    defmodule CredoImplTrueTest do
      @behaviour MyBehaviour

      @impl MyBehaviour
      def foo, do: :bar
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report when no @impl found" do
    ~S'''
    defmodule CredoImplTrueTest do
      def foo, do: :bar
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report @impl true" do
    ~S'''
    defmodule CredoTypespecTest do
      @impl true
      def foo, do: :bar
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue(%{line_no: 2, trigger: "@impl"})
  end
end
