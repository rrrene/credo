defmodule Credo.Check.Design.DuplicatedCodeTest do
  use Credo.TestHelper

  @described_check Credo.Check.Design.DuplicatedCode

  alias Credo.Check.Design.DuplicatedCode

  test "should raise an issue for duplicated code" do
    s1 = """
defmodule M1 do
  def myfun(p1, p2) when is_list(p2) do
    if p1 == p2 do
      p1
    else
      p2 + p1
    end
  end
end
""" |> to_source_file
    s2 = """
defmodule M2 do
  def myfun(p1, p2) when is_list(p2) do
    if p1 == p2 do
      p1
    else
      p2 + p1
    end
  end
end
""" |> to_source_file

    [s1, s2] = @described_check.run([s1, s2])
    refute Enum.empty?(s1.issues)
    refute Enum.empty?(s2.issues)
  end



  # unit tests for different aspects

  test "returns correct hashes, prunes and masses" do
    {:ok, ast} = """
defmodule M1 do
  def myfun(p1, p2) when is_list(p2) do
    if p1 == p2 do
      p1
    else
      p2 + p1
    end
  end
end

defmodule M2 do
  def myfun(p1, p2) when is_list(p2) do
    if p1 == p2 do
      p1
    else
      p2 + p1
    end
  end
end
""" |> Code.string_to_quoted

    hashes = DuplicatedCode.hashes(ast)
    pruned = DuplicatedCode.prune_hashes(hashes)
    assert 1 == Enum.count(pruned)

    with_masses = DuplicatedCode.add_masses(pruned)

    #IO.inspect {:masses, Enum.at(with_masses, 0)}
    {_hash, subnodes} = Enum.at(with_masses, 0)
    assert subnodes |> Enum.all?(fn(%{mass: mass}) -> mass == 19 end)
  end

  test "returns correct hashes, prunes and masses for multiple sources" do
    {:ok, ast1} = """
defmodule M1 do
  def myfun(p1, p2) when is_list(p2) do
    if p1 == p2 do
      p1
    else
      p2 + p1
    end
  end
end
""" |> Code.string_to_quoted
    {:ok, ast2} = """
defmodule M2 do
  def myfun(p1, p2) when is_list(p2) do
    if p1 == p2 do
      p1
    else
      p2 + p1
    end
  end
end
""" |> Code.string_to_quoted

    hashes = DuplicatedCode.hashes(ast1, %{}, "m1.ex")
    hashes = DuplicatedCode.hashes(ast2, hashes, "m2.ex")
    pruned = DuplicatedCode.prune_hashes(hashes)
    assert 1 == Enum.count(pruned)

    with_masses = DuplicatedCode.add_masses(pruned)

    #IO.inspect {:masses, Enum.at(with_masses, 0)}
    {_hash, subnodes} = Enum.at(with_masses, 0)
    assert subnodes |> Enum.all?(fn(%{mass: mass}) -> mass == 19 end)
  end



  test "returns correct hashes" do
    {:ok, ast} = """
defmodule M1 do
  def myfun(p1, p2) when is_list(p2) do
    if p1 == p2 do
      p1
    else
      p2 + p1
    end
  end
end

defmodule M2 do
  def myfun2(p1, p2) do
    if p1 == p2 do
      p1
    else
      p2 + p1
    end
  end
end
""" |> Code.string_to_quoted

    DuplicatedCode.hashes(ast)
  end


  test "returns ast without metadata" do
    ast =
      {:__block__, [],
 [{:defmodule, [line: 1],
   [{:__aliases__, [counter: 0, line: 1], [:M1]},
    [do: {:def, [line: 2],
      [{:when, [line: 2],
        [{:myfun, [line: 2], [{:p1, [line: 2], nil}, {:p2, [line: 2], nil}]},
         {:is_list, [line: 2], [{:p2, [line: 2], nil}]}]},
       [do: {:if, [line: 3],
         [{:==, [line: 3], [{:p1, [line: 3], nil}, {:p2, [line: 3], nil}]},
          [do: {:p1, [line: 4], nil},
           else: {:+, [line: 6],
            [{:p2, [line: 6], nil}, {:p1, [line: 6], nil}]}]]}]]}]]},
  {:defmodule, [line: 11],
   [{:__aliases__, [counter: 0, line: 11], [:M2]},
    [do: {:def, [line: 12],
      [{:myfun2, [line: 12], [{:p1, [line: 12], nil}, {:p2, [line: 12], nil}]},
       [do: {:if, [line: 13],
         [{:==, [line: 13], [{:p1, [line: 13], nil}, {:p2, [line: 13], nil}]},
          [do: {:p1, [line: 14], nil},
           else: {:+, [line: 16],
            [{:p2, [line: 16], nil}, {:p1, [line: 16], nil}]}]]}]]}]]}]}
    expected =
      {:__block__, [],
       [{:defmodule, [],
         [{:__aliases__, [], [:M1]},
          [do: {:def, [],
            [{:when, [],
              [{:myfun, [], [{:p1, [], nil}, {:p2, [], nil}]},
               {:is_list, [], [{:p2, [], nil}]}]},
             [do: {:if, [],
               [{:==, [], [{:p1, [], nil}, {:p2, [], nil}]},
                [do: {:p1, [], nil},
                 else: {:+, [],
                  [{:p2, [], nil}, {:p1, [], nil}]}]]}]]}]]},
        {:defmodule, [],
         [{:__aliases__, [], [:M2]},
          [do: {:def, [],
            [{:myfun2, [], [{:p1, [], nil}, {:p2, [], nil}]},
             [do: {:if, [],
               [{:==, [], [{:p1, [], nil}, {:p2, [], nil}]},
                [do: {:p1, [], nil},
                 else: {:+, [],
                  [{:p2, [], nil}, {:p1, [], nil}]}]]}]]}]]}]}
    assert expected == DuplicatedCode.remove_metadata(ast)
  end


  test "returns correct mass" do
    {:ok, ast} = """
defmodule M1 do
  def myfun(p1, p2) do
    if p1 == p2 do
      p1
    else
      p2 + p1
    end
  end
end
""" |> Code.string_to_quoted
    assert 18 == DuplicatedCode.mass(ast)

    ast = {:defmodule, [line: 1], [{:__aliases__, [counter: 0, line: 1], [:SampleModule]},
      [do:
        {:def, [line: 2], [{:myfun, [line: 2], [{:p1, [line: 2], nil}, {:p2, [line: 2], nil}]},
          [do:
            {:if, [line: 3], [{:==, [line: 3], [{:p1, [line: 3], nil}, {:p2, [line: 3], nil}]},
              [do:
                {:p1, [line: 4], nil},
              else: {:+, [line: 6],
                [{:p2, [line: 6], nil}, {:p1, [line: 6], nil}]}]]}]]}]]}
    assert 18 == DuplicatedCode.mass(ast)
  end


  test "returns correct hash" do
    {:ok, ast} = """
if p1 == p2 do
  p1
else
  p2 + p1
end
""" |> Code.string_to_quoted
    expected = "E9FD5824275A94E20A327BCB1253F6DEA816ECD20AC4A58F2184345F3D422532"
    assert expected == DuplicatedCode.to_hash(ast)
  end

end
