defmodule Credo.Check.Readability.SpaceInParenthesesTest do
  use Credo.TestHelper

  @described_check Credo.Check.Consistency.SpaceInParentheses

  @without_spaces """
defmodule Credo.Sample1 do
  @default_sources_glob ~w(** *.{ex,exs})

  defmodule InlineModule do
    def foobar do
      {:ok} = File.read(filename)

      parse_code(t, {:some_tuple, 1})
      parse_code(t, acc <> ~s(\"\"\"))
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
  @with_spaces2 """
defmodule OtherModule3 do
  defmacro foo do
      { :ok } = File.read( filename )
  end

  defp bar do
    :ok
  end
end
"""
  @with_and_without_spaces """
defmodule OtherModule3 do
  defmacro foo do
    { :ok } = File.read( filename )
  end

  defp bar do
    {:ok, :test}
  end
end
"""

  test "it should report the correct result " do
    [
      @without_spaces
    ]
    |> to_source_files()
    |> refute_issues(@described_check)
  end

  test "it should report the correct result 1" do
    [
      @with_spaces, @with_spaces2
    ]
    |> to_source_files()
    |> refute_issues(@described_check)
  end

  test "it should report the correct result 2" do
    [
      @without_spaces, @with_spaces, @with_spaces2
    ]
    |> to_source_files()
    |> assert_issues(@described_check)
  end

  test "it should report the correct result 3" do
    [
      @with_and_without_spaces
    ]
    |> to_source_files()
    |> assert_issue(@described_check)
  end

end
