defmodule Credo.Check.Readability.VariableNamesTest do
  use Credo.TestHelper

  @described_check Credo.Check.Readability.VariableNames

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
"""
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    some_value = parameter1 + parameter2
    {some_value, _} = parameter1
    [1, some_value] = parameter1
    [some_value | tail] = parameter1
    "e" <> some_value = parameter1
    ^some_value = parameter1
    %{some_value: some_value} = parameter1
    ... = parameter1
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
    someValue = parameter1 + parameter2
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation /2" do
"""
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    someOtherValue = parameter1 + parameter2
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation /3" do
"""
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    {true, someValue} = parameter1
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation /4" do
"""
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    [1, someValue] = parameter1
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation /5" do
"""
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    [someValue | tail] = parameter1
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation /6" do
"""
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    "e" <> someValue = parameter1
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation /7" do
"""
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    ^someValue = parameter1
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation /8" do
"""
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    %{some_value: someValue} = parameter1
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report multiple violations" do
"""
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    %{some_value: someValue, other_value: otherValue} = parameter1
  end
end
""" |> to_source_file
    |> assert_issues(@described_check)
  end
end
