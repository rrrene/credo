defmodule Credo.Check.Refactor.VariableRebindingTest do
  use Credo.TestHelper

  @described_check Credo.Check.Refactor.VariableRebinding

  test "it should NOT report expected code" do
"""
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    a = 1
    b = 2
  end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should report a violation" do
"""
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    a = 1
    a = 2
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report two violations" do
"""
defmodule CredoSampleModule do
  def some_function() do
    var_1 = 1 + 3
    var_b = var_1 + 7
    var_1 = 34
    var_c = 2456
    var_b = 2
  end
end
""" |> to_source_file
    |> assert_issues(@described_check, nil, &(length(&1) == 2))
  end

  test "it should report violations when using destructuring tuples" do
"""
defmodule CredoSampleModule do
  def some_function() do
    something = "ABABAB"
    {:ok, something} = Base.decode16(something)
    {a, a} = {2, 2} # this should _not_ trigger it
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report violations when using destructuring with nested assignments" do
"""
defmodule CredoSampleModule do
  def some_function() do
    {a = b, a = b} = {1, 2}
    b = 2
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report violations when using destructuring lists" do
"""
defmodule CredoSampleModule do
  def some_function() do
    [a, b] = [1, 2]
    b = 2
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end
end
