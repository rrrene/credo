defmodule Credo.Check.Readability.LineEndingsTest do
  use Credo.TestHelper

  @described_check Credo.Check.Consistency.LineEndings

  test "it should report the correct scope" do
    [
"""
defmodule Credo.Sample do
  defmodule InlineModule do
    def foobar do
      {:ok} = File.read
    end
  end
end
""",
"""
defmodule OtherModule do
  defmacro foo do
    {:ok} = File.read
  end

  defp bar do
    :ok
  end
end
"""
    ]
    |> Enum.map(&to_source_file/1)
    |> refute_issues(@described_check)
  end

  test "it should report the correct scope 2" do
    [
      """
defmodule Credo.Sample do\r\n@test_attribute :foo\r\nend\r\n
""",
"""
defmodule Credo.Sample do
  defmodule InlineModule do
    def foobar do
      {:ok} = File.read
    end
  end
end
""",
"""
defmodule OtherModule do
  defmacro foo do
    {:ok} = File.read
  end

  defp bar do
    :ok
  end
end
"""
    ]
    |> Enum.map(&to_source_file/1)
    |> assert_issue(@described_check)
  end

end
