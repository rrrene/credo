defmodule Credo.Check.Warning.NameRedeclarationByAssignmentTest do
  use Credo.TestHelper

  @described_check Credo.Check.Warning.NameRedeclarationByAssignment

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
"""
defmodule CredoSampleModule do
  def fun1 do
    case fun2 do
      x -> x
      %{something: foobar} -> foobar
    end
    [a, b, 42] = fun2
    %{a: a, b: b, c: false} = fun2
    %SomeModule{a: a, b: b, c: false} = fun2

    fun2 + 1
  end

  defmacro fun2 do
    42
  end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  #
  # cases raising issues
  #

  test "it should report a violation 3" do
"""
defmodule CredoSampleModule do
  def fun1 do
    case xyz do
      x -> x
      %{something: foobar} -> foobar
    end
    [fun2, b, 42] = xyz # now the variable is used instead of the function
    %{a: a, b: b, c: false} = fun2
    %SomeModule{a: a, b: b, c: false} = fun2

    fun2 + 1
  end

  defmacro fun2 do
    42
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation 4" do
"""
defmodule CredoSampleModule do
  def fun1 do
    case xyz do
      x -> x
      %{something: foobar} -> foobar
    end
    [a, b, 42] = fun2
    %{a: fun2, b: b, c: false} = xyz # now the variable is used instead of the function
    %SomeModule{a: a, b: b, c: false} = fun2

    fun2 + 1
  end

  defmacro fun2 do
    42
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation 4/2" do
"""
defmodule CredoSampleModule do
  def fun1 do
    case xyz do
      x -> x
      %{something: foobar} -> foobar
    end
    [a, b, 42] = fun2
    %{"a" => fun2, "c" => false} = xyz # now the variable is used instead of the function
    %SomeModule{a: a, b: b, c: false} = fun2

    fun2 + 1
  end

  defmacro fun2 do
    42
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation 5" do
"""
defmodule CredoSampleModule do
  def fun1 do
    case xyz do
      x -> x
      %{something: foobar} -> foobar
    end
    [a, b, 42] = fun2
    %{a: a, b: b, c: false} = fun2
    %SomeModule{a: fun2, b: b, c: false} = xyz # now the variable is used instead of the function

    fun2 + 1
  end

  defmacro fun2 do
    42
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation 6" do
"""
defmodule CredoSampleModule do
  def fun1 do
    [{fun2, 2, b, 42}] = xyz # now the variable is used instead of the function
  end

  defmacro fun2 do
    42
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation when a variable is declared with the same name as a function" do
"""
defmodule CredoSampleModule do
  def fun1 do
    fun2 = 5
    fun2 + 1 # now the variable is used instead of the function
  end

  def fun2 do
    42
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report violations when variables are declared with the same name as existing functions" do
"""
defmodule CredoSampleModule do
  def fun1 do
    fun2 = 5
    fun3 = 5
    fun2 + fun3 # now the variables are used instead of the functions
  end

  def fun2 do
    42
  end

  defp fun3 do
    42
  end
end
""" |> to_source_file
    |> assert_issues(@described_check)
  end

  test "it should report violation when a name matches names in Kernel" do
"""
defmodule CredoSampleModule do
  def fun1 do
    byte_size = 5
    map_size = 5
    fun2 + fun3 # now the variables are used instead of the functions
  end

  def spawn do # redeclaring `spawn` might be confusing
    42
  end

  defp get_and_update_in do
    42
  end
end
""" |> to_source_file
    #|> assert_issues(@described_check)
  end

end
