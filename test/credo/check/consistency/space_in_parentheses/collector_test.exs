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
  @heredoc_example """
  string = ~s\"\"\"
  "[]"
  \"\"\"

  another_string = ~s\"\"\"
  "[ ]"
  \"\"\"
  """

  test "it should report correct frequencies for without_spaces" do
    without_spaces =
      @without_spaces
      |> to_source_file()
      |> Collector.collect_matches([])

    assert %{without_space: 6, without_space_allow_empty_enums: 6} == without_spaces
  end

  test "it should report correct frequencies for with_spaces" do
    with_spaces =
      @with_spaces
      |> to_source_file()
      |> Collector.collect_matches([])

    assert %{with_space: 4} == with_spaces
  end

  test "it should report correct frequencies for empty enums" do
    empty_enum =
      ~S'''
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
      '''
      |> to_source_file()
      |> Collector.collect_matches([])

    assert %{with_space: 8, without_space: 6, without_space_allow_empty_enums: 4} == empty_enum
  end

  test "it should report correct frequencies for empty enums /2" do
    empty_enum =
      ~S'''
      defmodule Credo.Sample2 do
        defmodule InlineModule do
          def foobar do
            foo({ :ok, %{}, [] })
          end
        end
      end
      '''
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
