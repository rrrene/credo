defmodule Credo.Test.SourceFilesTest do
  use ExUnit.Case, async: true

  import Credo.Test.SourceFiles

  test "it should convert valid code to source file" do
    source_file =
      """
      defmodule CredoSampleModule do
        def some_function(parameter1, parameter2) do
          some_value = parameter1 + parameter2
        end
      end
      """
      |> to_source_file("example.ex")

    assert source_file.status == :valid
  end

  test "it should convert valid code to list of source files" do
    source_files =
      [
        """
        defmodule CredoSampleModule do
          def some_function(parameter1, parameter2) do
            some_value = parameter1 + parameter2
          end
        end
        """,
        """
        defmodule CredoSampleModule do
          def some_function(parameter1, parameter2) do
            some_value = parameter1 + parameter2
          end
        end
        """
      ]
      |> to_source_files()

    assert Enum.count(source_files) == 2

    assert List.first(source_files).status == :valid
  end

  test "it should report a violation" do
    s1 = """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        someValue = parameter1 +
    end
    """

    assert_raise(RuntimeError, fn -> to_source_file(s1, "example.ex") end)
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
end
