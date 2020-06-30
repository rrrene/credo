defmodule Credo.Check.Readability.ParameterPatternMatchingTest do
  use Credo.Test.Case

  @described_check Credo.Check.Consistency.ParameterPatternMatching
  @left_and_right_mix """
  defmodule Credo.Sample do
    defmodule InlineModule do
      def list_after([bar, baz] = foo), do: :ok

      def struct_before(foo_left = %User{name: name}), do: :ok
      def struct_after(%User{name: name} = foo), do: :ok

      defp map_before(foo_left = %{bar: baz}), do: :ok
      defp map_after(%{bar: baz} = foo), do: :ok
    end
  end
  """
  @var_left_list """
  defmodule Test do
    def test(foo = [x, y, x]) do
      nil
    end
  end
  """
  @var_left_tuple """
  defmodule Test do
    def test(foo = {x, y, x}) do
      nil
    end
  end
  """
  @var_left_struct """
  defmodule Test do
    def test(foo = %Foo{hello: "world"}) do
      nil
    end
  end
  """
  @var_left_map """
  defmodule Test do
    def test(foo = %{abc: def}) do
      nil
    end
  end
  """

  @var_right_list """
  defmodule Test do
    def test([x, y, x] = foo) do
      nil
    end
  end
  """
  @var_right_tuple """
  defmodule Test do
    def test({x, y, x} = foo) do
      nil
    end
  end
  """
  @var_right_struct """
  defmodule Test do
    def test(%Foo{hello: "world"} = foo) do
      nil
    end
  end
  """
  @var_right_map """
  defmodule Test do
    def test(%{abc: def} = foo) do
      nil
    end
  end
  """

  #
  # cases NOT raising issues
  #

  test "it should NOT report issues when variable decalrations are consistently on the left side" do
    [@var_left_map, @var_left_struct, @var_left_list]
    |> to_source_files
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report issues when variable decalrations are consistently on the right side" do
    [@var_right_map, @var_right_struct, @var_right_list]
    |> to_source_files
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT break when input has a function without bindings or private funs" do
    module_with_fun_without_bindings = """
    defmodule SurviveThisIfYouCan do
      def start do
        GenServer.start(__MODULE__, [])
      end

      defp foo(bar) do
        bar + 1
      end
    end
    """

    [module_with_fun_without_bindings]
    |> to_source_files
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report issues when variable declarations are mixed on the left and right side when pattern matching" do
    [@left_and_right_mix]
    |> to_source_files
    |> run_check(@described_check)
    |> assert_issues(fn issues ->
      assert Enum.any?(issues, fn issue ->
               issue.trigger == :foo_left && issue.line_no == 5
             end)

      assert Enum.any?(issues, fn issue ->
               issue.trigger == :foo_left && issue.line_no == 8
             end)

      assert 2 == Enum.count(issues)
    end)
  end

  test "it should report issues when variable decalrations are inconsistent throughout sourcefiles" do
    issues =
      [
        @var_right_map,
        @var_right_struct,
        @var_right_tuple,
        @var_right_list,
        @var_left_map,
        @var_left_tuple,
        @var_left_list
      ]
      |> to_source_files
      |> run_check(@described_check)
      |> assert_issues()

    assert 3 == Enum.count(issues)
  end

  test "it should report issues when variable decalrations are inconsistent throughout sourcefiles (preffering left side)" do
    issues =
      [
        @var_right_map,
        @var_right_struct,
        @var_right_list,
        @var_left_map,
        @var_left_struct,
        @var_left_tuple,
        @var_left_list
      ]
      |> to_source_files
      |> run_check(@described_check)
      |> assert_issues()

    assert 3 == Enum.count(issues)
  end
end
