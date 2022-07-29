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
  defmodule Credo.Sample do\r\n@test_attribute :foo\r\nend
  """

  #
  # cases NOT raising issues
  #

  test "it should not report expected code for linux" do
    [@unix_line_endings, @unix_line_endings2]
    |> to_source_files
    |> run_check(@described_check)
    |> refute_issues
  end

  test "it should not report expected code for windows" do
    [@windows_line_endings |> String.trim()]
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

  describe "autofix/1" do
    test "switches unix to windows line endings" do
      starting = "defmodule Credo.Sample do\n@test_attribute :foo\nend\n"
      expected = "defmodule Credo.Sample do\r\n@test_attribute :foo\r\nend\r\n"

      issue = %Credo.Issue{message: "File is using unix line endings while most of the files use windows line endings."}

      assert @described_check.autofix(starting, issue) == expected
    end

    test "switches windows to unix line endings" do
      starting = """
      defmodule Credo.Sample do\r\n@test_attribute :foo\r\nend
      """

      expected = """
      defmodule Credo.Sample do\n@test_attribute :foo\nend
      """

      issue = %Credo.Issue{message: "File is using windows line endings while most of the files use unix line endings."}

      assert @described_check.autofix(starting, issue) == expected
    end
  end
end
