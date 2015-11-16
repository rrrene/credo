defmodule Credo.Check.Warning.IExPryTest do
  use Credo.TestHelper

  @described_check Credo.Check.Warning.IExPry

  test "it should NOT report expected code" do
"""
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    parameter1 + parameter2
  end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should report a violation" do
"""
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    x = parameter1 + parameter2
    IEx.pry
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end
end
