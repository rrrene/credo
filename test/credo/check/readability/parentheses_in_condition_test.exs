defmodule Credo.Check.Readability.ParenthesesInConditionTest do
  use Credo.TestHelper

  @described_check Credo.Check.Readability.ParenthesesInCondition

  test "it should NOT report expected code" do
"""
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    unless allowed? do
      something
    end

    if File.exists?(filename) do
      something
    else
      something_else
    end
    if !allowed? || (something_in_parentheses == 42) do
      something
    end
    if (something_in_parentheses == 42) || !allowed? do
      something
    end
    if !allowed? == (something_in_parentheses == 42) do
      something
    end
    unless (something_in_parentheses != 42) || allowed? do
      something
    end
    boolean |> if(do: :ok, else: :error)
    boolean |> unless(do: :ok)
    if (thing && other_thing) || better_thing, do: something
    if !better_thing && (thing || other_thing), do: something_else
  end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should NOT report expected code /2" do
"""
defmodule CredoSampleModule do
  def some_function(username) do
    props =
      if(valid?(username), do: [:authorized]) ++
      unless(admin?(username), do: [:restricted])
  end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end




  test "it should report a violation" do
"""
defmodule Mix.Tasks.Credo do
  def run(argv) do
    if( allowed? ) do
      true
    else
      false
    end
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report violations with oneliners if used with parentheses" do
"""
defmodule Mix.Tasks.Credo do
  def run(argv) do
    if (allowed?), do: true
    unless (!allowed?), do: true
  end
end
""" |> to_source_file
    |> assert_issues(@described_check)
  end

  test "it should report a violation if used with parentheses" do
"""
defmodule Mix.Tasks.Credo do
  def run(argv) do
    unless( !allowed? ) do
      true
    else
      false
    end
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report violations with spaces before the parentheses" do
"""
defmodule Mix.Tasks.Credo do
  def run(argv) do
    if ( allowed? ) do
      true
    else
      false
    end

    unless (also_allowed?) do
      true
    end
  end
end
""" |> to_source_file
    |> assert_issues(@described_check)
  end
end
