defmodule Credo.Check.Consistency.SpaceAroundOperators.WithoutSpaceTest do
  use Credo.TestHelper

  alias Credo.Check.Consistency.SpaceAroundOperators.WithoutSpace

  @with_spaces ~S"""
defmodule Credo.Sample2 do
  @other [?., ?-, ?+]
  @specials ~c|()<>@,;:\\"/[]?={}|

  defmodule InlineModule do
    def foobar({:=, _, arguments}) do
      range = -999..-1
      3 * 4
      for op <- [:{}, :%{}, :^, :|, :<>] do
      end
      something = removed != []
      Enum.map(dep.deps, &(&1.app)) ++ current_breadths
    end
  end
end
"""
  @without_spaces """
defmodule Credo.Sample1 do
  defmodule InlineModule do
    def foobar do
      1+2
    end
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

  test "it should NOT report anything" do
    result =
      @with_spaces
      |> to_source_file()
      |> WithoutSpace.property_value_for([])
      |> Enum.reject(&is_nil/1)

    assert [] == result
  end

  @tag :to_be_implemented
  test "it should NOT report anything for special cases" do
    result =
      @with_spaces_special_cases
      |> to_source_file()
      |> WithoutSpace.property_value_for([])
      |> Enum.reject(&is_nil/1)

    assert [] == result
  end


  test "it should report some values" do
    result =
      @without_spaces
      |> to_source_file()
      |> WithoutSpace.property_value_for([])
      |> Enum.reject(&is_nil/1)

    assert 1 == Enum.count(result)
  end
end
