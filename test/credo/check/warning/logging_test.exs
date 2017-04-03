defmodule Credo.Check.Warning.LazyLoggingTest do
  use Credo.TestHelper

  @described_check Credo.Check.Warning.LazyLogging

  #
  # cases NOT raising issues
  #

  test "it should NOT report lazzy logging" do
"""
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    Logger.debug fn ->
      "A debug message: #{inspect 1}"
    end
  end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should NOT report imported :debug from Logger" do
"""
defmodule CredoSampleModule do
  import Logger, only: debug

  def some_function(parameter1, parameter2) do
    debug fn ->
      "Some message: #\{CredoSampleModule\}"
    end
  end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should NOT report for debug function" do
"""
defmodule CredoSampleModule do
  import Enum

  def debug(whatever) do
    whatever
  end

  def some_function(parameter1, parameter2) do
    debug "Inspected: #\{CredoSampleModule\}"
  end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should NOT report for non interpolated strings" do
"""
defmodule CredoSampleModule do
  def some_function do
    Logger.debug "Hallo"
  end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should NOT report for function call" do
"""
defmodule CredoSampleModule do

  def message do
    "Imma message"
  end

  def some_function do
    Logger.debug message
  end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  #
  # cases raising issues
  #

  test "it should report a violation for interpolated strings" do
"""
defmodule CredoSampleModule do

  def some_function(parameter1, parameter2) do
    var_1 = "Hello world"
    Logger.warn "The module: #\{var1\}"
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation with imported :debug from Logger" do
"""
defmodule CredoSampleModule do
  import Logger

  def some_function(parameter1, parameter2) do
    debug "Ok #\{inspect 1\}"
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

end
