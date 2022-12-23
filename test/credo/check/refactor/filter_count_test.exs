defmodule Credo.Check.Refactor.FilterCountTest do
  use Credo.Test.Case

  @described_check Credo.Check.Refactor.FilterCount

  #
  # cases NOT raising issues
  #

  test "does not trigger when using Enum.count/2" do
    """
    defmodule Credo.Sample.Module do
      def some_function(p1, p2, p3, p4, p5) do
        Enum.count([1, 2, 3], fn x -> rem(x, 3) == 0 end)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "does not trigger when piping list into Enum.filter/2 and piping result of that into Enum.count/2" do
    """
    defmodule Credo.Sample.Module do
      def some_function(p1, p2, p3, p4, p5) do
        [1, 2, 3]
        |> Enum.filter(fn x -> rem(x, 3) == 0 end)
        |> Enum.count(fn x -> x > 2 end)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "does not trigger when filter-count pipeline is part of a larger pipeline using Enum.count/2" do
    """
    defmodule Credo.Sample.Module do
      def some_function(p1, p2, p3, p4, p5) do
        [1, 2, 3]
        |> Enum.sort()
        |> Enum.filter(fn x -> rem(x, 3) == 0 end)
        |> Enum.count(fn x -> x > 2 end)
        |> then(fn x -> x + 1 end)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "does not trigger when piping list into Enum.filter/2 and passing result as parameter to Enum.count/2" do
    """
    defmodule Credo.Sample.Module do
      def some_function(p1, p2, p3, p4, p5) do
        Enum.count([1, 2, 3] |> Enum.filter(fn x -> rem(x, 3) == 0 end), fn x -> x > 2 end)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "does not trigger when applying Enum.filter/2 to two arguments and passing result to Enum.count/2" do
    """
    defmodule Credo.Sample.Module do
      def some_function(p1, p2, p3, p4, p5, p6) do
        Enum.count(Enum.filter([1, 2, 3], fn x -> rem(x, 3) == 0 end), fn x -> x > 2 end)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "does not trigger when applying Enum.filter/2 to two arguments and piping into Enum.count/2" do
    """
    defmodule Credo.Sample.Module do
      def some_function(p1, p2, p3, p4, p5) do
        Enum.filter([1, 2, 3], fn x -> rem(x, 3) == 0 end)
        |> Enum.count(fn x -> x > 2 end)
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

  test "triggers when piping list into Enum.filter/2 and piping result of that into Enum.count/1" do
    """
    defmodule Credo.Sample.Module do
      def some_function(p1, p2, p3, p4, p5) do
        [1, 2, 3]
        |> Enum.filter(fn x -> rem(x, 3) == 0 end)
        |> Enum.count()
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "triggers when filter-count pipeline is part of a larger pipeline" do
    """
    defmodule Credo.Sample.Module do
      def some_function(p1, p2, p3, p4, p5) do
        [1, 2, 3]
        |> Enum.sort()
        |> Enum.filter(fn x -> rem(x, 3) == 0 end)
        |> Enum.count()
        |> then(fn x -> x + 1 end)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "triggers when piping list into Enum.filter/2 and passing result as parameter to Enum.count/1" do
    """
    defmodule Credo.Sample.Module do
      def some_function(p1, p2, p3, p4, p5) do
        Enum.count([1, 2, 3] |> Enum.filter(fn x -> rem(x, 3) == 0 end))
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "triggers when applying Enum.filter/2 to two arguments and passing result to Enum.count/1" do
    """
    defmodule Credo.Sample.Module do
      def some_function(p1, p2, p3, p4, p5, p6) do
        Enum.count(Enum.filter([1, 2, 3], fn x -> rem(x, 3) == 0 end))
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "triggers when applying Enum.filter/2 to two arguments and piping into Enum.count/1" do
    """
    defmodule Credo.Sample.Module do
      def some_function(p1, p2, p3, p4, p5) do
        Enum.filter([1, 2, 3], fn x -> rem(x, 3) == 0 end)
        |> Enum.count()
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end
end
