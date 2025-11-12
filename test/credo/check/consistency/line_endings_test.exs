defmodule Credo.Check.Consistency.LineEndingsTest do
  use Credo.Test.Case

  @described_check Credo.Check.Consistency.LineEndings

  @unix_line_endings ~S'''
  defmodule Credo.Sample do
    defmodule InlineModule do
      def foobar do
        {:ok} = File.read
      end
    end
  end
  '''
  @unix_line_endings2 ~S'''
  defmodule OtherModule do
    defmacro foo do
      {:ok} = File.read
    end

    defp bar do
      :ok
    end
  end
  '''
  @windows_line_endings ~s'''
  defmodule Credo.Sample do\r\n@test_attribute :foo\r\nend
  '''

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code for linux" do
    [@unix_line_endings, @unix_line_endings2]
    |> to_source_files
    |> run_check(@described_check)
    |> refute_issues
  end

  test "it should NOT report expected code for windows" do
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
    |> assert_issue(fn issue ->
      assert issue.trigger == "\r\n"
    end)
  end

  test "it should report an issue here when there is no problem, but the :force param specifies the other kind of line ending" do
    [@windows_line_endings]
    |> to_source_files
    |> run_check(@described_check, force: :unix)
    |> assert_issue(fn issue ->
      assert issue.trigger == "\r\n"
    end)
  end
end
