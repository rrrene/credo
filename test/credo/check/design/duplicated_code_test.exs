defmodule Credo.Check.Design.DuplicatedCodeTest do
  use Credo.TestHelper

  @described_check Credo.Check.Design.DuplicatedCode

  alias Credo.Check.Design.DuplicatedCode
  alias Credo.Service.SourceFileIssues

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

    source_files = [s1, s2]
    :ok = @described_check.run(source_files)
    [s1, s2] = SourceFileIssues.update_in_source_files(source_files)

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

    hashes = DuplicatedCode.calculate_hashes(ast)
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

    hashes = DuplicatedCode.calculate_hashes(ast1, %{}, "m1.ex")
    hashes = DuplicatedCode.calculate_hashes(ast2, hashes, "m2.ex")
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

    DuplicatedCode.calculate_hashes(ast)
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
