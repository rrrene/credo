defmodule Credo.Check.Refactor.InefficientEnumAggregationsTest do
  use Credo.Test.Case

  @described_check Credo.Check.Refactor.InefficientEnumAggregations

  #
  # cases NOT raising issues
  #

  test "does not report purpose-built aggregate functions" do
    ~S'''
    defmodule Sample do
      def sum(items), do: Enum.sum_by(items, & &1.amount)
      def product(items), do: Enum.product_by(items, & &1.quantity)
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "does not report unrelated modules or aggregations" do
    ~S'''
    defmodule Sample do
      def sum(items), do: Other.sum(Enum.map(items, & &1.amount))
      def map(items), do: Enum.sum(Other.map(items, & &1.amount))
      def count(items), do: Enum.count(Enum.map(items, & &1.amount))
      def values(items), do: Enum.sum_by(Other.values(items), & &1.amount)
      def aggregate(items), do: Other.sum_by(Map.values(items), & &1.amount)
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "does not report Map.values when constructing the mapper might have side effects" do
    ~S'''
    defmodule Sample do
      def sum(items), do: items |> Map.values() |> Enum.sum_by(build_mapper())
      def product(items), do: Enum.product_by(Map.values(items), build_mapper())
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "reports Enum.map or Stream.map piped into Enum.sum or Enum.product" do
    for {mapper, aggregate, trigger} <- [
          {:Enum, :sum, "sum"},
          {:Stream, :sum, "sum"},
          {:Enum, :product, "product"},
          {:Stream, :product, "product"}
        ] do
      """
      defmodule Sample do
        def aggregate(items) do
          items
          |> #{mapper}.map(& &1.amount)
          |> Enum.#{aggregate}()
        end
      end
      """
      |> to_source_file()
      |> run_check(@described_check)
      |> assert_issue(%{line_no: 5, trigger: trigger})
    end
  end

  test "reports nested map and aggregate calls" do
    for {mapper, aggregate, trigger} <- [
          {:Enum, :sum, "sum"},
          {:Stream, :sum, "sum"},
          {:Enum, :product, "product"},
          {:Stream, :product, "product"}
        ] do
      """
      defmodule Sample do
        def aggregate(items), do: Enum.#{aggregate}(#{mapper}.map(items, & &1.amount))
      end
      """
      |> to_source_file()
      |> run_check(@described_check)
      |> assert_issue(%{line_no: 2, trigger: trigger})
    end
  end

  test "reports mixed call and pipe forms" do
    ~S'''
    defmodule Sample do
      def sum(items), do: Enum.sum(items |> Enum.map(& &1.amount))
      def product(items), do: Enum.map(items, & &1.amount) |> Enum.product()
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issues(fn issues ->
      assert Enum.sort(Enum.map(issues, & &1.trigger)) == ["product", "sum"]
    end)
  end

  test "reports an inefficient aggregation within a longer pipeline" do
    ~S'''
    defmodule Sample do
      def aggregate(items) do
        items
        |> Enum.sort()
        |> Enum.map(& &1.amount)
        |> Enum.sum()
        |> round()
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue(%{line_no: 6, trigger: "sum"})
  end

  test "reports Map.values piped into aggregate-by functions" do
    for {aggregate_by, mapper, trigger} <- [
          {:sum_by, "mapper", "sum_by"},
          {:sum_by, "& &1.amount", "sum_by"},
          {:product_by, "fn value -> value.quantity end", "product_by"}
        ] do
      """
      defmodule Sample do
        def aggregate(items) do
          items
          |> Map.values()
          |> Enum.#{aggregate_by}(#{mapper})
        end
      end
      """
      |> to_source_file()
      |> run_check(@described_check)
      |> assert_issue(%{line_no: 5, trigger: trigger})
    end
  end

  test "reports nested Map.values and aggregate-by calls" do
    ~S'''
    defmodule Sample do
      def sum(items), do: Enum.sum_by(Map.values(items), & &1.amount)
      def product(items), do: Enum.product_by(Map.values(items), mapper)
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issues(fn issues ->
      assert Enum.sort(Enum.map(issues, & &1.trigger)) == ["product_by", "sum_by"]
    end)
  end

  test "reports Map.values without parentheses" do
    ~S'''
    defmodule Sample do
      def sum(items), do: items |> Map.values() |> Enum.sum_by(mapper)
      def product(items), do: items |> Map.values |> Enum.product_by(& &1.quantity)
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issues(fn issues -> assert length(issues) == 2 end)
  end

  test "reports Map.values followed by map and aggregate as one opportunity" do
    ~S'''
    defmodule Sample do
      def sum(items) do
        items
        |> Map.values()
        |> Enum.map(& &1.amount)
        |> Enum.sum()
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue(%{line_no: 6, trigger: "sum"})
  end

  test "reports mixed Map.values and aggregate-by call forms" do
    ~S'''
    defmodule Sample do
      def sum(items), do: Enum.sum_by(items |> Map.values(), & &1.amount)
      def product(items), do: Map.values(items) |> Enum.product_by(& &1.quantity)
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issues(fn issues ->
      assert Enum.sort(Enum.map(issues, & &1.trigger)) == ["product_by", "sum_by"]
    end)
  end
end
