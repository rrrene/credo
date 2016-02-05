defmodule Credo.Check.Readability.SpaceAroundOperatorsTest do
  use Credo.TestHelper

  @described_check Credo.Check.Consistency.SpaceAroundOperators

  @without_spaces """
defmodule Credo.Sample1 do
  defmodule InlineModule do
    def foobar do
      1+2
    end
  end
end
"""
  @with_spaces """
defmodule Credo.Sample2 do
  defmodule InlineModule do
    def foobar do
      [3 * 4]
      |> my_func(&Some.Deep.Module.is_something/1)
    end
  end
end
"""
  @with_spaces2 """
defmodule OtherModule3 do
  defmacro foo do
    1 && 2
  end

  defp bar do
    :ok
  end
end
"""
  @with_spaces3 """
defmodule OtherModule3 do
  defmacro foo do
    case foo do
      {line_no, line} -> nil
      {line_no, line} ->
        nil
    end
  end
end
"""
  @with_and_without_spaces """
defmodule OtherModule3 do
  defmacro foo do
    3+4
  end

  defp bar do
    6 *7
  end
end
"""
  @with_and_without_spaces2 """
defmodule OtherModule3 do
  defmacro foo do
    3+4
  end

  defp bar do
    [3 /4]
    |> my_func(&Some.Deep.Module.is_something/1)
  end
end
"""

  test "it should report the correct result" do
    [
      @with_spaces, @with_spaces2, @with_spaces3
    ]
    |> to_source_files()
    |> refute_issues(@described_check)
  end

  test "it should report an issue for mixed styles /1" do
    [
      @without_spaces, @with_spaces, @with_spaces2
    ]
    |> to_source_files()
    |> assert_issue(@described_check)
  end

  test "it should report an issue for mixed styles /2" do
    [
      @without_spaces, @with_spaces2, @with_spaces2
    ]
    |> to_source_files()
    |> assert_issue(@described_check)
  end

  test "it should report the correct result 4" do
    [
      @with_and_without_spaces
    ]
    |> to_source_files()
    |> assert_issue(@described_check)
  end

end
