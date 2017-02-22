defmodule Credo.Check.Warning.LoggingTest do
  use Credo.TestHelper

  @described_check Credo.Check.Warning.Logging

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
"""
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    Logger.debug fn ->
        "my_fun/1: input: #{inspect 1}"
    end
  end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should NOT report imported Logger" do
"""
defmodule CredoSampleModule do
  import Logger
  def some_function(parameter1, parameter2) do
    debug fn ->
        "lazy/1: input: #{inspect 1}"
    end
  end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
"""
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
      Logger.debug "my_fun/1: input: #{inspect 1}"
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation with imported name" do
"""
defmodule CredoSampleModule do
  import Logger
  def some_function(parameter1, parameter2) do
    debug "violation/1: input: #{inspect 1}"
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end
end
