defmodule Credo.Check.Warning.LazyLoggingTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.LazyLogging

  #
  # cases NOT raising issues
  #

  test "it should NOT report lazzy logging" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        Logger.debug fn ->
          "A debug message: #{inspect(1)}"
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report imported :debug from Logger" do
    ~S'''
    defmodule CredoSampleModule do
      import Logger, only: debug

      def some_function(parameter1, parameter2) do
        debug fn ->
          "Some message: #\{CredoSampleModule\}"
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report for user-defined debug function" do
    ~S'''
    defmodule CredoSampleModule do
      import Enum

      def debug(whatever) do
        whatever
      end

      def some_function(parameter1, parameter2) do
        debug "Inspected: #\{CredoSampleModule\}"
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report for non interpolated strings" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function do
        Logger.debug "Hallo"
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report for function call" do
    ~S'''
    defmodule CredoSampleModule do

      def message do
        "Imma message"
      end

      def some_function do
        Logger.debug message
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation with :levels param" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        Logger.debug "Ok #\{inspect 1\}"
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, ignore: [:debug])
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation for interpolated strings" do
    ~S'''
    defmodule CredoSampleModule do

      def some_function(parameter1, parameter2) do
        var_1 = "Hello world"
        Logger.debug "The module: #{var1}"
        Logger.debug "The module: #{var1}"
        Logger.debug "The module: #{var1}"
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues(fn [three, two, one] ->
      assert one.trigger == "Logger.debug"
      assert one.line_no == 5
      assert one.column == 5

      assert two.trigger == "Logger.debug"
      assert two.line_no == 6
      assert two.column == 5

      assert three.trigger == "Logger.debug"
      assert three.line_no == 7
      assert three.column == 5
    end)
  end

  test "it should report a violation with imported :debug from Logger" do
    ~S'''
    defmodule CredoSampleModule do
      import Logger

      def some_function(parameter1, parameter2) do
        debug "Ok #{inspect 1}"
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "debug"
      assert issue.line_no == 5
      assert issue.column == 5
    end)
  end
end
