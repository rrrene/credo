defmodule Credo.Check.Consistency.ParameterPatternMatching.CollectorTest do
  use Credo.Test.Case

  alias Credo.Check.Consistency.ParameterPatternMatching.Collector

  @special_cases """
  defmodule SpecialCases do
    def foo([bar, _] = baz), do: :ok
    defp foo(baz = [bar, _]), do: :ok

    def special(foo = [bar, _]) when is_list(foo), do: :ok
    def special([bar, _] = foo) when is_tuple(bar) do
      case bar do
        status = {:ok, _} -> status
        {:error, _} = status -> status
        wat = {:wat, n} when n > 0 -> wat
        {:wat, n} = wat when is_tuple(wat) -> wat
      end
      fn
        admin = %User{admin: true} -> admin
        %User{} = user -> user
        wat = {:wat, n} when is_number(n) -> wat
      end
    end
  end
  """

  @tag :to_be_implemented
  test "it should report correct frequencies for special cases" do
    result =
      @special_cases
      |> to_source_file()
      |> Collector.collect_matches([])

    assert %{before: 6, after: 5} == result
  end
end
