defmodule Credo.Check.Refactor.FilterRejectTest do
  use Credo.Test.Case

  @described_check Credo.Check.Refactor.FilterReject

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    defmodule Credo.Sample.Module do
      def some_function(p1, p2, p3, p4, p5) do
        Enum.reject(["a", "b", "c"], fn letter ->
          !String.contains?(letter, "x") && String.contains?(letter, "a")
        end)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    """
    defmodule Credo.Sample.Module do
      def some_function(p1, p2, p3, p4, p5) do
        ["a", "b", "c"]
        |> Enum.filter(&String.contains?(&1, "x"))
        |> Enum.reject(&String.contains?(&1, "a"))
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation 2" do
    """
    defmodule Credo.Sample.Module do
      def some_function(p1, p2, p3, p4, p5, p6) do
        Enum.reject(Enum.filter([:a, :b, :c], &String.contains?(&1, "x")), &String.contains?(&1, "a"))
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation 3" do
    """
    defmodule Credo.Sample.Module do
      def some_function(p1, p2, p3, p4, p5) do
        [:a, :b, :c]
        |> Enum.sort()
        |> Enum.filter(&String.contains?(&1, "x"))
        |> Enum.reject(&String.contains?(&1, "a"))
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation 4" do
    """
    defmodule Credo.Sample.Module do
      def some_function(p1, p2, p3, p4, p5) do
        [:a, :b, :c]
        |> Enum.sort()
        |> Enum.filter(&String.contains?(&1, "x"))
        |> Enum.reject(&String.contains?(&1, "a"))
        |> Enum.sort()
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation 5" do
    """
    defmodule Credo.Sample.Module do
      def some_function(p1, p2, p3, p4, p5) do
        Enum.filter([:a, :b, :c], &String.contains?(&1, "x"))
        |> Enum.reject(&String.contains?(&1, "a"))
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation 6" do
    """
    defmodule Credo.Sample.Module do
      def some_function(p1, p2, p3, p4, p5) do
        Enum.reject([:a, :b, :c] |> Enum.filter(&String.contains?(&1, "x")), &String.contains?(&1, "a"))
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end
end
