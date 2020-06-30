defmodule Credo.Check.Warning.RaiseInsideRescueTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.RaiseInsideRescue

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def catcher do
        try do
          raise "oops"
        rescue
          e in RuntimeError ->
            Logger.warn("Something bad happened")
          e ->
            reraise e, System.stacktrace
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report expected code /2" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def catcher do
        try do
          raise "oops"
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should report a violation when raise appears inside of a rescue block" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def catcher do
        try do
          raise "oops"
        rescue
          e in RuntimeError ->
            Logger.warn("Something bad happened")
            raise e
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert "raise" == issue.trigger
      assert 10 == issue.line_no
    end)
  end

  test "it should report a violation when raise appears inside of a rescue block for an implicit try" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def catcher do
        raise "oops"
      rescue
        e in RuntimeError ->
          Logger.warn("Something bad happened")
          raise e
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert "raise" == issue.trigger
      assert 9 == issue.line_no
    end)
  end

  test "it should report a violation when raise appears inside of an expression in rescue" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def catcher do
        try do
          raise "oops"
        rescue
          e -> Logger.warn("Something bad happened") && raise e
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert "raise" == issue.trigger
      assert 8 == issue.line_no
    end)
  end
end
