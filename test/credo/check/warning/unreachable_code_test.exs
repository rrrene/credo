defmodule Credo.Check.Warning.UnreachableCodeTest do
  use Credo.TestHelper

  @described_check Credo.Check.Warning.UnreachableCode

  @moduletag :to_be_implemented

  test "it should NOT report expected code" do
"""
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    parameter1 + parameter2
    raise "error!!!"
  end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should NOT report expected code /2" do
"""
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    if something? do
      parameter2
    else
      parameter1 + parameter2
      raise "error!!!"
    end
  end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end


  test "it should report a violation" do
"""
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    if something? do
      parameter2
    else
      raise "error!!!"
      parameter1 + parameter2
    end
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end
end
