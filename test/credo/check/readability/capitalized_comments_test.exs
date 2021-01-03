defmodule Credo.Check.Readability.CapitalizedCommentsTest do
  use Credo.Test.Case

  alias Credo.Check.Readability.CapitalizedComments

  @check_params [
    rules: [
      %{if_match: ~r/\n/, require_match: ~r/^(|[`'"0-9A-Z])$/m, message: "Message 1"},
      %{unless_match: ~r/\n/, require_match: ~r/[\.\?\!]\E/m, message: "Message 2"}
    ]
  ]

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
    """
    |> to_source_file()
    |> run_check(CapitalizedComments, @check_params)
    |> refute_issues()
  end

  test "when comments starts with \` or \' or \" or 0-9 or A-Z and last comment line ends with \. or \? or \!" do
    """
    # This is an valid comment
    # so, no issues.

    # oh, no

    # `code` block!
    # New comment follows.

    # "wow", this is also valid:
    #
    #   def code(x) do
    #     IO.inspect x
    #   end

    # 'also', this is valid?
    # - yes
    # - and yes

    # 9 is also valid,
    # but you need to be more
    # clear what 9 means.
    """
    |> to_source_file()
    |> run_check(CapitalizedComments, @check_params)
    |> refute_issues()
  end

  test "non-capitalized start" do
    """
    # invalid comment.

    # this is also invalid single comment
    """
    |> to_source_file()
    |> run_check(CapitalizedComments, @check_params)
    |> assert_issues(fn [issue_1, issue_2] ->
      assert "# invalid comment." == issue_2.trigger
      assert "# this is" == issue_1.trigger
    end)
  end

  test "non-capitalized multi-comment start" do
    """
    # this comment is invalid,
    # so it should be captured.
    """
    |> to_source_file()
    |> run_check(CapitalizedComments, @check_params)
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
    |> run_check(CapitalizedComments, @check_params)
    |> assert_issues(fn [issue_1, issue_2, issue_3] ->
      assert "# so this" == issue_3.trigger
      assert "# also, this" == issue_2.trigger
      assert "# same, this" == issue_1.trigger
    end)
  end
end
