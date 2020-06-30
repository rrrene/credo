defmodule Credo.Check.Refactor.MapIntoTest do
  use Credo.Test.Case

  @described_check Credo.Check.Refactor.MapInto

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    defmodule Credo.Sample.Module do
      def some_function(p1, p2, p3, p4, p5) do
        Enum.into([:apple, :banana, :carrot], %{}, &({&1, to_string(&1)}))

        my_list
        |> Enum.map(&square/1)
        |> Enum.into(%{}, &to_tuple/1)

        Enum.into(Enum.map(my_list, &square/1), %{}, &to_tuple/1)
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
        [:apple, :banana, :carrot]
        |> Enum.map(&({&1, to_string(&1)}))
        |> Enum.into(%{})
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
        Enum.into(Enum.map([:a, :b, :c], &({&1, to_string(&1)})), %{})
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
        [:apple, :banana, :carrot]
        |> Enum.sort()
        |> Enum.map(&({&1, to_string(&1)}))
        |> Enum.into(%{})
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
        [:apple, :banana, :carrot]
        |> Enum.map(&({&1, to_string(&1)}))
        |> Enum.into(%{})
        |> Map.keys()
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
        Enum.map([:apple, :banana, :carrot], &({&1, to_string(&1)}))
        |> Enum.into(%{})
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
        Enum.into([:apple, :banana, :carrot] |> Enum.map(&({&1, to_string(&1)})), %{})
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end
end
