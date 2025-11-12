defmodule Credo.Check.Design.DuplicatedCodeTest do
  use Credo.Test.Case

  @described_check Credo.Check.Design.DuplicatedCode

  alias Credo.Check.Design.DuplicatedCode

  #
  # cases NOT raising issues
  #

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

  #
  # cases raising issues
  #

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

    expected = "6717D763C5F93296274CAD8867D61690CD4F0E9D64D2217FC4C20540C2826CF4"

    assert expected == DuplicatedCode.to_hash(ast)
  end

  test "returns correct hash and mass /2" do
    {:ok, ast} =
      """
      test "returns {:ok, result} when reply and :DOWN in message queue" do
        task = %Task{ref: make_ref(), owner: self(), pid: nil, mfa: {__MODULE__, :test, 1}}
        send(self(), {task.ref, :result})
        send(self(), {:DOWN, task.ref, :process, self(), :abnormal})
        assert Task.yield_many([task], 0) == [{task, {:ok, :result}}]
        refute_received {:DOWN, _, _, _, _}
      end
      """
      |> Code.string_to_quoted()

    ast_expected =
      {:test, [line: 1],
       [
         "returns {:ok, result} when reply and :DOWN in message queue",
         [
           do:
             {:__block__, [],
              [
                {:=, [line: 2],
                 [
                   {:task, [line: 2], nil},
                   {:%, [line: 2],
                    [
                      {:__aliases__, [line: 2], [:Task]},
                      {:%{}, [line: 2],
                       [
                         ref: {:make_ref, [line: 2], []},
                         owner: {:self, [line: 2], []},
                         pid: nil,
                         mfa: {:{}, [line: 2], [{:__MODULE__, [line: 2], nil}, :test, 1]}
                       ]}
                    ]}
                 ]},
                {:send, [line: 3],
                 [
                   {:self, [line: 3], []},
                   {{{:., [line: 3], [{:task, [line: 3], nil}, :ref]}, [no_parens: true, line: 3],
                     []}, :result}
                 ]},
                {:send, [line: 4],
                 [
                   {:self, [line: 4], []},
                   {:{}, [line: 4],
                    [
                      :DOWN,
                      {{:., [line: 4], [{:task, [line: 4], nil}, :ref]},
                       [no_parens: true, line: 4], []},
                      :process,
                      {:self, [line: 4], []},
                      :abnormal
                    ]}
                 ]},
                {:assert, [line: 5],
                 [
                   {:==, [line: 5],
                    [
                      {{:., [line: 5], [{:__aliases__, [line: 5], [:Task]}, :yield_many]},
                       [line: 5], [[{:task, [line: 5], nil}], 0]},
                      [{{:task, [line: 5], nil}, {:ok, :result}}]
                    ]}
                 ]},
                {:refute_received, [line: 6],
                 [
                   {:{}, [line: 6],
                    [
                      :DOWN,
                      {:_, [line: 6], nil},
                      {:_, [line: 6], nil},
                      {:_, [line: 6], nil},
                      {:_, [line: 6], nil}
                    ]}
                 ]}
              ]}
         ]
       ]}

    assert ast_expected == ast

    expected =
      "8A00FB049ABAAC6444CDAD783246B6C715BD994FF9B59F1546BC009EE0F93469"

    assert expected == DuplicatedCode.to_hash(ast)
  end

  test "returns different hashes for different code snippets" do
    {:ok, ast} =
      """
      test "returns {:ok, result} when reply and :DOWN in message queue" do
        task = %Task{ref: make_ref(), owner: self(), pid: nil, mfa: {__MODULE__, :test, 1}}
        send(self(), {task.ref, :result})
        send(self(), {:DOWN, task.ref, :process, self(), :abnormal})
        assert Task.yield_many([task], 0) == [{task, {:ok, :result}}]
        refute_received {:DOWN, _, _, _, _}
      end
      """
      |> Code.string_to_quoted()

    # uses `Task.yield` instead of `Task.yield_many`
    {:ok, ast2} =
      """
      test "returns {:ok, result} when reply and :DOWN in message queue" do
        task = %Task{ref: make_ref(), owner: self(), pid: nil, mfa: {__MODULE__, :test, 1}}
        send(self(), {task.ref, :result})
        send(self(), {:DOWN, task.ref, :process, self(), :abnormal})
        assert Task.yield(task, 0) == {:ok, :result}
        refute_received {:DOWN, _, _, _, _}
      end
      """
      |> Code.string_to_quoted()

    assert ast != ast2
    assert DuplicatedCode.to_hash(ast) != DuplicatedCode.to_hash(ast2)
  end
end
