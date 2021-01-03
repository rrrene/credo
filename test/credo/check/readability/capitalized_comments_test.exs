defmodule Credo.Check.Readability.CapitalizedCommentsTest do
  use Credo.Test.Case

  alias Credo.Check.Readability.CapitalizedComments

  describe "valid single line comment" do
    test "when comments starts with \` or \' or \" or 0-9 or A-Z and ends with \. or \? or \!" do
      """
      # This is an valid comment.

      # `code` block!

      # "wow", this is also valid.

      # 'also', this is valid?

      # 9 is also valid.

      # * starting with other symbol is valid.

      # - this is also valid.

      # valid_single_word_comment

      ############################
      ## This is a valid comment #
      ############################
      """
      |> to_source_file()
      |> run_check(CapitalizedComments)
      |> refute_issues()
    end
  end

  describe "valid multi-line comments" do
    test "when comments starts with \` or \' or \" or 0-9 or A-Z and last comment line ends with \. or \? or \!" do
      """
      # This is an valid comment
      # so, no issues.

      # `code` block!
      # New comment follows.

      # "wow", this is also valid:
      # def code(x) do
      #   IO.inspect x
      # end

      # 'also', this is valid?
      # - yes
      # - and yes

      # 9 is also valid,
      # but you need to be more
      # clear what 9 means.
      """
      |> to_source_file()
      |> run_check(CapitalizedComments)
      |> refute_issues()
    end
  end

  describe "invalid single line comment" do
    test "non-capitalized start" do
      """
      # invalid comment.

      # this is also invalid single comment
      """
      |> to_source_file()
      |> run_check(CapitalizedComments)
      |> assert_issues(fn [issue_1, issue_2] ->
        assert "# invalid comment." == issue_2.trigger
        assert "# this is" == issue_1.trigger
      end)
    end
  end

  describe "invalid multi-line comments" do
    test "non-capitalized multi-comment start" do
      """
      # this comment is invalid,
      # so it should be captured.
      """
      |> to_source_file()
      |> run_check(CapitalizedComments)
      |> assert_issues(fn [issue_1, issue_2] ->
        assert "# this comment" == issue_2.trigger
        assert "# so it" == issue_1.trigger
      end)
    end

    test "new non-capitalized single comment start after multi-comment end" do
      """
      # This comment is invalid
      # but now it has ended.
      # so this comment is invalid

      # This comment is invalid
      # but now it has ended with?
      # also, this comment is invalid

      # This comment is invalid
      # but now it has ended with!
      # same, this comment is invalid
      """
      |> to_source_file()
      |> run_check(CapitalizedComments)
      |> assert_issues(fn [issue_1, issue_2, issue_3] ->
        assert "# so this" == issue_3.trigger
        assert "# also, this" == issue_2.trigger
        assert "# same, this" == issue_1.trigger
      end)
    end
  end

  describe "configurable params" do
    test "excluded_files" do
      """
        # file with invalid comment
      """
      |> to_source_file("sample.ex")
      |> run_check(CapitalizedComments, excluded_files: ["sample.ex"])
      |> refute_issues()
    end

    test "excluded_paths" do
      """
        # file with invalid comment
      """
      |> to_source_file("hello/sample.ex")
      |> run_check(CapitalizedComments, excluded_paths: ["hello/"])
      |> refute_issues()
    end

    test "non_capitalized_sentence" do
      """
        # Let us make this valid in regex
      """
      |> to_source_file("hello/sample.ex")
      |> run_check(CapitalizedComments, non_capitalized_sentence: ~r/\# [A-Z] .*/)
      |> refute_issues()
    end

    test "capitalized_sentence_without_end" do
      """
        # let us make this valid in regex
      """
      |> to_source_file("hello/sample.ex")
      |> run_check(CapitalizedComments, capitalized_sentence_without_end: ~r/\# [a-z]*.*/)
      |> refute_issues()
    end

    test "comment_sentence_without_end" do
      """
        # Let us make this valid in regex
        # and this will pass.
        # for sure
      """
      |> to_source_file("hello/sample.ex")
      |> run_check(CapitalizedComments, comment_sentence_without_end: ~r/\# [a-z]*.*\.$/)
      |> refute_issues()
    end
  end
end
