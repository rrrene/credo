defmodule Credo.Check.Design.DuplicatedCodeTest do
  use Credo.Test.Case

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
    """

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
    """

    [s1, s2]
    |> to_source_files
    |> run_check(@described_check, mass_threshold: 16)
    |> assert_issues()
  end

  test "should raise an issue for duplicated code via macros" do
    s1 = """
    defmodule M1 do
      test "something is duplicated" do
        if p1 == p2 do
          p1
        else
          p2 + p1
          if p1 == p2 do
            p1
          else
            p2 + p1
          end
        end
      end
    end
    """

    s2 = """
    defmodule M2 do
      test "something is duplicated" do
        if p1 == p2 do
          p1
        else
          p2 + p1
          if p1 == p2 do
            p1
          else
            p2 + p1
          end
        end
      end
    end
    """

    [s1, s2]
    |> to_source_files
    |> run_check(@described_check, mass_threshold: 16)
    |> assert_issues()
  end

  test "should raise an issue for duplicated code with different line numbers and external function call" do
    s1 = """
    defmodule M1 do
      def myfun(p1, p2) when is_list(p2) do
        if p1 == p2 do
          A.f(p1)
        else
          p2 + p1
        end
      end
    end
    """

    s2 = """
    defmodule M2 do
      # additional line here
      def myfun(p1, p2) when is_list(p2) do
        if p1 == p2 do
          A.f(p1)
        else
          p2 + p1
        end
      end
    end
    """

    [s1, s2]
    |> to_source_files
    |> run_check(@described_check, mass_threshold: 16)
    |> assert_issues()
  end

  test "should NOT raise an issue for duplicated code via macros if macros are in :excluded_macros param" do
    s1 = """
    defmodule M1 do
      test "something is duplicated" do
        if p1 == p2 do
          p1
        else
          p2 + p1
          if p1 == p2 do
            p1
          else
            p2 + p1
          end
        end
      end
    end
    """

    s2 = """
    defmodule M2 do
      test "something is duplicated" do
        if p1 == p2 do
          p1
        else
          p2 + p1
          if p1 == p2 do
            p1
          else
            p2 + p1
          end
        end
      end
    end
    """

    [s1, s2]
    |> to_source_files
    |> run_check(@described_check, excluded_macros: [:test])
    |> refute_issues
  end

  # unit tests for different aspects

  test "returns correct hashes, prunes and masses" do
    {:ok, ast} =
      """
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
      """
      |> Code.string_to_quoted()

    mass_threshold = 16
    hashes = DuplicatedCode.calculate_hashes(ast, %{}, "foo.ex", mass_threshold)
    pruned = DuplicatedCode.prune_hashes(hashes, mass_threshold)
    assert 1 == Enum.count(pruned)

    with_masses = DuplicatedCode.add_masses(pruned)

    # IO.inspect {:masses, Enum.at(with_masses, 0)}
    {_hash, subnodes} = Enum.at(with_masses, 0)
    assert subnodes |> Enum.all?(fn %{mass: mass} -> mass == 19 end)
  end

  test "returns correct hashes, prunes and masses for multiple sources" do
    {:ok, ast1} =
      """
      defmodule M1 do
        def myfun(p1, p2) when is_list(p2) do
          if p1 == p2 do
            p1
          else
            p2 + p1
          end
        end
      end
      """
      |> Code.string_to_quoted()

    {:ok, ast2} =
      """
      defmodule M2 do
        def myfun(p1, p2) when is_list(p2) do
          if p1 == p2 do
            p1
          else
            p2 + p1
          end
        end
      end
      """
      |> Code.string_to_quoted()

    mass_threshold = 16
    hashes = DuplicatedCode.calculate_hashes(ast1, %{}, "m1.ex", mass_threshold)

    hashes = DuplicatedCode.calculate_hashes(ast2, hashes, "m2.ex", mass_threshold)

    pruned = DuplicatedCode.prune_hashes(hashes, mass_threshold)
    assert 1 == Enum.count(pruned)

    with_masses = DuplicatedCode.add_masses(pruned)

    # IO.inspect {:masses, Enum.at(with_masses, 0)}
    {_hash, subnodes} = Enum.at(with_masses, 0)
    assert subnodes |> Enum.all?(fn %{mass: mass} -> mass == 19 end)
  end

  test "returns correct hashes" do
    {:ok, ast} =
      """
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
      """
      |> Code.string_to_quoted()

    DuplicatedCode.calculate_hashes(ast)
  end

  test "returns correct mass" do
    {:ok, ast} =
      """
      defmodule M1 do
        def myfun(p1, p2) do
          if p1 == p2 do
            p1
          else
            p2 + p1
          end
        end
      end
      """
      |> Code.string_to_quoted()

    assert 18 == DuplicatedCode.mass(ast)

    ast =
      {:defmodule, [line: 1],
       [
         {:__aliases__, [counter: 0, line: 1], [:SampleModule]},
         [
           do:
             {:def, [line: 2],
              [
                {:myfun, [line: 2], [{:p1, [line: 2], nil}, {:p2, [line: 2], nil}]},
                [
                  do:
                    {:if, [line: 3],
                     [
                       {:==, [line: 3],
                        [
                          {:p1, [line: 3], nil},
                          {:p2, [line: 3], nil}
                        ]},
                       [
                         do: {:p1, [line: 4], nil},
                         else:
                           {:+, [line: 6],
                            [
                              {:p2, [line: 6], nil},
                              {:p1, [line: 6], nil}
                            ]}
                       ]
                     ]}
                ]
              ]}
         ]
       ]}

    assert 18 == DuplicatedCode.mass(ast)
  end

  test "returns correct hash" do
    {:ok, ast} =
      """
      if p1 == p2 do
        p1
      else
        p2 + p1
      end
      """
      |> Code.string_to_quoted()

    # Elixir <= 1.5.x
    expected = "E9FD5824275A94E20A327BCB1253F6DEA816ECD20AC4A58F2184345F3D422532"

    # Elixir >= 1.6.0
    expected_160 = "100B2E81FB13BEEFDC7E514AC56F10385340A7DC6535144A0FBC8EB74C37AEEB"

    assert expected == DuplicatedCode.to_hash(ast) or expected_160 == DuplicatedCode.to_hash(ast)
  end
end
