defmodule Credo.Check.Consistency.SpaceInParentheses.CollectorTest do
  use Credo.Test.Case

  alias Credo.Check.Consistency.SpaceInParentheses.Collector

  @without_spaces """
  defmodule Credo.Sample1 do
    defmodule InlineModule do
      def foobar do
        {:ok} = File.read(filename)
        {
          :multi_line_tuple,
          File.read(filename) # completely fine
        }
      end
    end
  end
  """
  @with_spaces """
  defmodule Credo.Sample2 do
    defmodule InlineModule do
      def foobar do
        { :ok } = File.read( filename )
      end
    end
  end
  """
  @with_spaces_empty_enum """
    defmodule Credo.Sample2 do
      defmodule InlineModule do
        def foobar do
          exists = File.exists?(filename)
          { result, %{} } = File.read( filename )
        end

        def barfoo do
          exists = File.exists?(filename)
          { result, [] } = File.read( filename )
        end
      end
    end
  """

  @heredoc_example """
  string = ~s\"\"\"
  "[]"
  \"\"\"

  another_string = ~s\"\"\"
  "[ ]"
  \"\"\"
  """

  test "it should report correct frequencies" do
    without_spaces =
      @without_spaces
      |> to_source_file()
      |> Collector.collect_matches([])

    assert %{without_space: 2, without_space_allow_empty_enums: 2} == without_spaces

    with_spaces =
      @with_spaces
      |> to_source_file()
      |> Collector.collect_matches([])

    assert %{with_space: 1} == with_spaces

    empty_enum =
      @with_spaces_empty_enum
      |> to_source_file()
      |> Collector.collect_matches([])

    assert %{with_space: 2, without_space: 4, without_space_allow_empty_enums: 2} == empty_enum
  end

  test "it should NOT report heredocs containing sigil chars" do
    values =
      @heredoc_example
      |> to_source_file
      |> Collector.collect_matches([])

    assert %{} == values
  end
end
