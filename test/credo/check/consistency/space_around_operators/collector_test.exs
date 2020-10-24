defmodule Credo.Check.Consistency.SpaceAroundOperators.CollectorTest do
  use Credo.Test.Case

  alias Credo.Check.Consistency.SpaceAroundOperators.Collector

  test "it should report correct frequencies for operators surrounded by spaces" do
    result =
      """
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
      |> to_source_file()
      |> Collector.collect_matches([])

    assert %{with_space: 18} == result
  end

  test "it should report correct frequencies for operators surrounded by spaces /2" do
    result =
      """
      a = b + c + compare_fn.(-d, 0)
      """
      |> to_source_file()
      |> Collector.collect_matches([])

    assert %{with_space: 3} == result
  end

  test "it should report correct frequencies for operators surrounded by spaces /3" do
    result =
      """
      a = b + c + compare_fn.(-d, 0)
      """
      |> to_source_file()
      |> Collector.collect_matches([])

    assert %{with_space: 3} == result
  end

  test "it should report correct frequencies for operators not surrounded by spaces" do
    result =
      """
      defmodule Credo.Sample2 do
        def foobar do
          1+2
        end
      end
      """
      |> to_source_file()
      |> Collector.collect_matches([])

    assert %{without_space: 1} == result
  end

  test "it should report correct frequencies for mixed cases" do
    result =
      """
      defmodule Credo.Sample3 do
        def foobar do
          1+ 2
          3 *4
        end
      end
      """
      |> to_source_file()
      |> Collector.collect_matches([])

    assert %{with_space: 2, without_space: 2} == result
  end
end
