defmodule Credo.SourceFileTest do
  use Credo.Test.Case

  test "it should NOT report expected code" do
    source_file =
      """
      defmodule CredoSampleModule do
        def some_function(parameter1, parameter2) do
          some_value = parameter1 + parameter2
        end
      end
      """
      |> Credo.SourceFile.parse("example.ex")

    assert source_file.status == :valid
  end

  test "it should report a violation" do
    s1 = """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        someValue = parameter1 +
    end
    """

    source_file = Credo.SourceFile.parse(s1, "example.ex")

    assert source_file.status == :invalid
  end

  test "it should return line and column correctly" do
    source_file =
      """
      defmodule CredoSampleModule do
        def some_function(parameter1, parameter2) do
          some_value = parameter1 + parameter2
        end
      end
      """
      |> to_source_file

    assert "    some_value = parameter1 + parameter2" == Credo.SourceFile.line_at(source_file, 3)

    assert 18 == Credo.SourceFile.column(source_file, 3, :parameter1)
    assert 1 == Credo.SourceFile.column(source_file, 1, :defmodule)
  end

  test "it should return line and column correctly with same term in line" do
    source_file =
      """
      defmodule CredoSampleModule do
        def prune_hashes(hashes, parameter2) do
          some_hashes = hashes + parameter2
        end
      end
      """
      |> to_source_file

    assert 20 == Credo.SourceFile.column(source_file, 2, :hashes)
    assert 19 == Credo.SourceFile.column(source_file, 3, :hashes)
  end

  test "it should return line and column correctly with same term in line /2" do
    source_file =
      """
      defmodule CredoSampleModule do
        def foo!, do: impl().foo!()
        def foo?, do: impl().foo?()
      end
      """
      |> to_source_file

    assert 7 == Credo.SourceFile.column(source_file, 2, :foo!)
    assert 7 == Credo.SourceFile.column(source_file, 3, :foo?)
  end
end
