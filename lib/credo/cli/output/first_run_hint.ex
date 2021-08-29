defmodule Credo.CLI.Output.FirstRunHint do
  alias Credo.CLI.Output
  alias Credo.CLI.Output.UI
  alias Credo.Execution

  @lots_of_issue_threshold 30
  @command_padding 40
  @category_count 5

  def call(exec) do
    term_width = Output.term_columns()
    issues = Execution.get_issues(exec)

    headline = " 8< "
    bar = String.pad_leading("", div(term_width - String.length(headline), 2), "-")

    UI.puts()
    UI.puts()
    UI.puts([:magenta, :bright, "#{bar} 8< #{bar}"])
    UI.puts()
    UI.puts()

    issue_count = Enum.count(issues)

    readability_issue_count =
      issues
      |> Enum.filter(&(&1.category == :readability))
      |> Enum.count()

    relative_issue_count_per_category = div(issue_count, @category_count)

    mostly_readability_issues =
      readability_issue_count >= div(@lots_of_issue_threshold, 2) &&
        readability_issue_count > relative_issue_count_per_category * 2

    readability_hint =
      if mostly_readability_issues do
        [
          """

          While not recommended, you could simply start ignoring issues for the time being:

          """,
          :cyan,
          String.pad_trailing("    mix credo --ignore readability", @command_padding),
          :faint,
          "# exclude checks matching a given phrase",
          "\n",
          :reset
        ]
      else
        []
      end

    if issue_count >= @lots_of_issue_threshold do
      UI.puts([
        :reset,
        :orange,
        """
        # Where to start?
        """,
        :reset,
        """

        That's a lot of issues to deal with at once.
        """,
        readability_hint
      ])
    else
      UI.puts([
        :reset,
        :orange,
        """
        # How to introduce Credo
        """,
        :reset,
        """

        This is looking pretty already! You can probably just fix the issues above in one go.

        """,
        readability_hint
      ])
    end

    print_lots_of_issues(exec)

    UI.puts([
      :reset,
      :orange,
      """

      ## Every project is different
      """,
      :reset,
      """

      Introducing code analysis to an existing codebase should not be about following any
      "best practice" in particular, it should be about helping you to get to know the ropes
      and make the changes you want.

      Try the options outlined above to see which one is working for this project!
      """
    ])
  end

  defp print_lots_of_issues(exec) do
    working_dir = Execution.working_dir(exec)
    now = now()
    default_branch = default_branch(working_dir)
    latest_commit_on_default_branch = latest_commit_on_default_branch(working_dir)
    latest_tag = latest_tag(working_dir)

    current_branch = current_branch(working_dir)

    if current_branch != default_branch do
      UI.puts([
        :reset,
        """
        You can use `diff` to only show the issues that were introduced on this branch:
        """,
        :cyan,
        """

            mix credo diff #{default_branch}

        """
      ])
    end

    UI.puts([
      :reset,
      :orange,
      """
      ## Compare to a point in history
      """,
      :reset,
      """

      Alternatively, you can use `diff` to only show the issues that were introduced after a certain tag or commit:
      """
    ])

    if latest_tag do
      UI.puts([
        :cyan,
        String.pad_trailing("    mix credo diff #{latest_tag} ", @command_padding),
        :faint,
        "# use the latest tag",
        "\n"
      ])
    end

    UI.puts([
      :reset,
      :cyan,
      String.pad_trailing(
        "    mix credo diff #{latest_commit_on_default_branch}",
        @command_padding
      ),
      :faint,
      "# use the current HEAD of #{default_branch}",
      "\n\n",
      :reset,
      """
      Lastly, you can compare your working dir against this point in time:

      """,
      :cyan,
      String.pad_trailing("    mix credo diff --since #{now}", @command_padding),
      :faint,
      "# use the current date",
      "\n"
    ])
  end

  defp latest_tag(working_dir) do
    case System.cmd("git", ~w"rev-list --tags --max-count=1", cd: working_dir) do
      {"", 0} ->
        nil

      {latest_tag_sha1, 0} ->
        case System.cmd("git", ~w"describe --tags #{latest_tag_sha1}", cd: working_dir) do
          {tagname, 0} -> String.trim(tagname)
          _ -> nil
        end

      _ ->
        nil
    end
  end

  defp current_branch(working_dir) do
    case System.cmd("git", ~w"rev-parse --abbrev-ref HEAD", cd: working_dir) do
      {output, 0} -> String.trim(output)
      _ -> nil
    end
  end

  defp default_branch(working_dir) do
    remote_name = default_remote_name(working_dir)

    case System.cmd("git", ~w"symbolic-ref refs/remotes/#{remote_name}/HEAD", cd: working_dir) do
      {output, 0} -> ~r"refs/remotes/#{remote_name}/(.+)$" |> Regex.run(output) |> Enum.at(1)
      _ -> nil
    end
  end

  defp default_remote_name(_working_dir) do
    "origin"
  end

  defp latest_commit_on_default_branch(working_dir) do
    case System.cmd(
           "git",
           ~w"rev-parse --short #{default_remote_name(working_dir)}/#{default_branch(working_dir)}",
           cd: working_dir
         ) do
      {output, 0} -> String.trim(output)
      _ -> nil
    end
  end

  defp now do
    %{year: year, month: month, day: day} = DateTime.utc_now()

    "#{year}-#{pad(month)}-#{pad(day)}"
  end

  defp pad(number) when number < 10, do: "0#{number}"
  defp pad(number), do: to_string(number)
end
