defmodule Credo.Check.Refactor.MapMapTest do
  use Credo.TestHelper

  @described_check Credo.Check.Refactor.MapMap

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    defmodule Credo.Sample.Module do
      def some_function(p1, p2, p3, p4, p5) do
        Enum.map([:a, :b, :c], fn letter ->
          letter
          |> inspect()
          |> String.upcase()
        end)
      end
    end
    """
    |> to_source_file
    |> refute_issues(@described_check)
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    """
    defmodule Credo.Sample.Module do
      def some_function(p1, p2, p3, p4, p5) do
        [:a, :b, :c]
        |> Enum.map(&inspect/1)
        |> Enum.map(&String.upcase/1)
      end
    end
    """
    |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation 2" do
    """
    defmodule Credo.Sample.Module do
      def some_function(p1, p2, p3, p4, p5, p6) do
        Enum.map(Enum.map([:a, :b, :c], &inspect/1), &String.upcase/1)
      end
    end
    """
    |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation 3" do
    """
    defmodule Credo.Sample.Module do
      def some_function(p1, p2, p3, p4, p5) do
        [:a, :b, :c]
        |> Enum.sort()
        |> Enum.map(&inspect/1)
        |> Enum.map(&String.upcase/1)
      end
    end
    """
    |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation 4" do
    """
    defmodule Credo.Sample.Module do
      def some_function(p1, p2, p3, p4, p5) do
        [:a, :b, :c]
        |> Enum.sort()
        |> Enum.map(&inspect/1)
        |> Enum.map(&String.upcase/1)
        |> Enum.filter(&is_nil/1)
      end
    end
    """
    |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation 5" do
    """
    defmodule Credo.Sample.Module do
      def some_function(p1, p2, p3, p4, p5) do
        Enum.map([:a, :b, :c], &inspect/1)
        |> Enum.map(&String.upcase/1)
      end
    end
    """
    |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation 6" do
    """
    defmodule Credo.Sample.Module do
      def some_function(p1, p2, p3, p4, p5) do
        Enum.map([:a, :b, :c] |> Enum.map(&inspect/1), &String.downcase/1)
      end
    end
    """
    |> to_source_file
    |> assert_issue(@described_check)
  end
end
