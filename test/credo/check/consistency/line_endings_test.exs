defmodule Credo.Check.Readability.LineEndingsTest do
  use Credo.Test.Case

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

  #
  # cases NOT raising issues
  #

  test "it should not report expected code" do
    [@unix_line_endings, @unix_line_endings2]
    |> to_source_files
    |> run_check(@described_check)
    |> refute_issues
  end

  #
  # cases raising issues
  #

  test "it should report an issue here" do
    [@unix_line_endings, @windows_line_endings]
    |> to_source_files
    |> run_check(@described_check)
    |> assert_issue
  end
end
