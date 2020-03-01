defmodule Credo.Check.Consistency.SpaceAroundOperators.CollectorTest do
  use Credo.Test.Case

  alias Credo.Check.Consistency.SpaceAroundOperators.Collector

  @with_space """
  defmodule Credo.Sample1 do
    defmodule InlineModule do
      def foobar do
        4 + 3
        4 - 3
        4 * 3
        a = 3
        4 && 3
        "4" <> "3"
        4 == 3
        [4] ++ [3]
        4 == 3
        4 > 3
        4 >= 3
        4 <= 3
        range = -999..-1
        for op <- [:{}, :%{}, :^, :|, :<>] do
        end
        something = removed != []
        Enum.map(dep.deps, &(&1.app)) ++ current_breadths
        &function_capture/1
        &:erlang_module.function_capture/3
        &Elixir.function_capture/3
        &@module.blah/1
        |> my_func(&Some.Deep.Module.is_something/1)
      end
    end
  end
  """
  @without_space """
  defmodule Credo.Sample2 do
    def foobar do
      1+2
    end
  end
  """
  @mixed """
  defmodule Credo.Sample3 do
    def foobar do
      1+ 2
      3 *4
    end
  end
  """
  @with_spaces_special_cases ~S"""
  defmodule Credo.Sample2 do
    defmodule InlineModule do
      def foobar do
        child_sources = Enum.drop(child_sources, -1)
        TestRepo.all(from p in Post, where: field(p, ^field) = datetime_add(^inserted_at, ^-3, ^"week"))
        {literal(-number, type, vars), params}
        {time2, _} = :timer.tc(&flush/0, [])
        {{:{}, [], [:==, [], [to_escaped_field(field), value]]}, params}
        <<_, unquoted::binary-size(size), _>> = quoted
        args = Enum.map_join ix+1..ix+length, ",", &"$#{&1}"
      end

      defp do_underscore(<<?-, t :: binary>>, _) do
      end

      def escape({:-, _, [number]}, type, params, vars, _env) when is_number(number) do
      end
    end
  end
  """

  test "it should report correct frequencies for operators surrounded by spaces" do
    result =
      @with_space
      |> to_source_file()
      |> Collector.collect_matches([])

    assert %{with_space: 18} == result
  end

  test "it should report correct frequencies for operators not surrounded by spaces" do
    result =
      @without_space
      |> to_source_file()
      |> Collector.collect_matches([])

    assert %{without_space: 1} == result
  end

  test "it should report correct frequencies for mixed cases" do
    result =
      @mixed
      |> to_source_file()
      |> Collector.collect_matches([])

    assert %{with_space: 2, without_space: 2} == result
  end

  @tag :to_be_implemented
  test "it should NOT report without_space for special cases" do
    result =
      @with_spaces_special_cases
      |> to_source_file()
      |> Collector.collect_matches([])

    assert %{} == Map.delete(result, :with_spaces)
  end
end
