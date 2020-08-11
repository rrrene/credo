defmodule Credo.Check.Readability.ImplTrueTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.ImplTrue

  test "it should NOT report @impl Behaviour" do
    """
    defmodule CredoImplTrueTest do
      @behaviour MyBehaviour

      @impl MyBehaviour
      def foo, do: :bar
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report when no @impl found" do
    """
    defmodule CredoImplTrueTest do
      def foo, do: :bar
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should report @impl true" do
    """
    defmodule CredoTypespecTest do
      @impl true
      def foo, do: :bar
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end
end
