defmodule Credo.Code.ParametersTest do
  use Credo.Test.Case

  alias Credo.Code.Parameters

  #
  # names
  #

  test "returns the correct parameter names" do
    {:ok, ast} =
      """
        def some_function(p1, p2, p3, p4, p5), do: :ok
      """
      |> Code.string_to_quoted()

    assert [:p1, :p2, :p3, :p4, :p5] == Parameters.names(ast)

    {:ok, ast} =
      """
      def foobar(parameter1, parameter2 \\\\ false) do
        :ok
      end
      """
      |> Code.string_to_quoted()

    assert [:parameter1, :parameter2] == Parameters.names(ast)

    {:ok, ast} =
      """
      def foobar(parameter2 \\\\ false, line: line, column: column) do
      :ok
      end
      """
      |> Code.string_to_quoted()

    assert [:parameter2, [:line, :column]] == Parameters.names(ast)

    {:ok, ast} =
      """
      defp foobar(<<h, t :: binary>>, prev) when h in ?A..?Z and not(prev in ?A..?Z) do
      :ok
      end
      """
      |> Code.string_to_quoted()

    assert [[:h, :t], :prev] == Parameters.names(ast)

    {:ok, ast} =
      """
      defp foobar(<<?-, t :: binary>>, _) do
      :ok
      end
      """
      |> Code.string_to_quoted()

    assert [[:t], :_] == Parameters.names(ast)

    #    {:ok, ast} = """
    # fn(a, b) ->
    #  :ok
    # end
    #    """ |> Code.string_to_quoted
    #    assert [:a, :b] == Parameters.names(ast)
  end

  test "returns the correct parameter names for pattern matches with structs" do
    {:ok, ast} =
      """
      def foobar(%{} = source_file, %Issue{line: line, column: column} = issue) do
      :ok
      end
      """
      |> Code.string_to_quoted()

    assert 2 == Parameters.count(ast)

    assert [[[], :source_file], [[:line, :column], :issue]] == Parameters.names(ast)
  end

  test "returns the correct parameter names for pattern matches with structs 2" do
    {:ok, ast} =
      """
      def foobar(%{ast: my_ast} = source_file, %Issue{line: line, column: column} = issue) do
      :ok
      end
      """
      |> Code.string_to_quoted()

    assert 2 == Parameters.count(ast)

    assert [[[:my_ast], :source_file], [[:line, :column], :issue]] == Parameters.names(ast)
  end

  #
  # count
  #

  test "returns the correct parameter counts" do
    {:ok, ast} =
      """
        def some_function(p1, p2, p3, p4, p5), do: :ok
      """
      |> Code.string_to_quoted()

    assert 5 == Parameters.count(ast)

    {:ok, ast} =
      """
      def foobar(parameter1, parameter2 \\\\ false) do
      :ok
      end
      """
      |> Code.string_to_quoted()

    assert 2 == Parameters.count(ast)

    {:ok, ast} =
      """
      def foobar(parameter2 \\\\ false, line: line) do
      :ok
      end
      """
      |> Code.string_to_quoted()

    assert 2 == Parameters.count(ast)

    {:ok, ast} =
      """
      defp foobar(<<h, t :: binary>>, prev) when h in ?A..?Z and not(prev in ?A..?Z) do
      :ok
      end
      """
      |> Code.string_to_quoted()

    assert 2 == Parameters.count(ast)

    {:ok, ast} =
      """
      defp foobar(<<?-, t :: binary>>, _) do
      :ok
      end
      """
      |> Code.string_to_quoted()

    assert 2 == Parameters.count(ast)
  end

  test "returns the correct parameter counts for ASTs" do
    ast =
      {:def, [line: 2],
       [
         {:some_function, [line: 2],
          [
            {:p1, [line: 2], nil},
            {:p2, [line: 2], nil},
            {:p3, [line: 2], nil},
            {:p4, [line: 2], nil},
            {:p5, [line: 2], nil}
          ]},
         [
           do:
             {:=, [line: 3],
              [
                {:some_value, [line: 3], nil},
                {:+, [line: 3],
                 [
                   {:parameter1, [line: 3], nil},
                   {:parameter2, [line: 3], nil}
                 ]}
              ]}
         ]
       ]}

    assert 5 == Parameters.count(ast)
  end
end
