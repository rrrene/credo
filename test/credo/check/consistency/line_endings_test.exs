defmodule Credo.Check.Readability.LineEndingsTest do
  use Credo.TestHelper

  @described_check Credo.Check.Consistency.LineEndings

  @unix_line_endings """
defmodule Credo.Sample do
  defmodule InlineModule do
    def foobar do
      {:ok} = File.read
    end
  end
end
"""
  @unix_line_endings2 """
defmodule OtherModule do
  defmacro foo do
    {:ok} = File.read
  end

  defp bar do
    :ok
  end
end
"""
  @windows_line_endings """
defmodule Credo.Sample do\r\n@test_attribute :foo\r\nend\r\n
"""

  test "it should report the correct scope" do
    [@unix_line_endings, @unix_line_endings2]
    |> Enum.map(&to_source_file/1)
    |> refute_issues(@described_check)
  end

  test "it should report the correct scope 2" do
    [@unix_line_endings, @windows_line_endings]
    |> Enum.map(&to_source_file/1)
    |> assert_issue(@described_check)
  end

end
