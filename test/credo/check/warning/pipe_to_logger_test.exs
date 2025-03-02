defmodule Credo.Check.Warning.PipeToLoggerTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.PipeToLogger

  #
  # cases NOT raising issues
  #

  test "it should NOT report when Logger is used without piping" do
    """
    defmodule CredoSampleModule do
      require Logger

      def some_function(parameter1) do
        Logger.warn("This is a direct call")
        Logger.info("Another direct call")

        something_else()
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report when piping to other functions" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1) do
        parameter1
        |> process_data()
        |> transform_result()
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report when Logger is in a different position" do
    """
    defmodule CredoSampleModule do
      require Logger

      def some_function(parameter1) do
        Logger.warn(parameter1 |> transform_data())

        # Other code
        result = other_function() |> process_result()

        result
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation when piping to Logger.warn" do
    """
    defmodule CredoSampleModule do
      require Logger

      def some_function(parameter1) do
        parameter1
        |> transform_data()
        |> Logger.warn()

        :ok
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.line_no == 7
      assert issue.column == 5
      assert issue.trigger == "|> Logger.warn"
    end)
  end

  test "it should report a violation when piping to any Logger function" do
    """
    defmodule CredoSampleModule do
      require Logger

      def some_function(parameter1) do
        "Starting process"
        |> Logger.info()

        parameter1
        |> transform_data()
        |> Logger.error()

        "Debug information"
        |> Logger.debug()

        :ok
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues(fn issues ->
      assert length(issues) == 3

      [issue1, issue2, issue3] = issues

      assert issue1.line_no == 6
      assert issue1.column == 5
      assert issue1.trigger == "|> Logger.info"

      assert issue2.line_no == 10
      assert issue2.column == 5
      assert issue2.trigger == "|> Logger.error"

      assert issue3.line_no == 13
      assert issue3.column == 5
      assert issue3.trigger == "|> Logger.debug"
    end)
  end

  test "it should report a violation when piping to Logger with options" do
    """
    defmodule CredoSampleModule do
      require Logger

      def some_function(error) do
        error
        |> inspect()
        |> Logger.error(some_metadata: "value")

        :error
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.line_no == 7
      assert issue.column == 5
      assert issue.trigger == "|> Logger.error"
    end)
  end
end
