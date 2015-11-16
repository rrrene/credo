defmodule Credo.Check.Warning.NameRedeclarationByCaseTest do
  use Credo.TestHelper

  @described_check Credo.Check.Warning.NameRedeclarationByCase

  test "it should NOT report expected code" do
"""
defmodule CredoSampleModule do
  use ExUnit.Case

  def fun1 do
    case fun2 do
      x -> x
      %{something: foobar} -> foobar
    end
  end

  defmacro fun2 do
    42
  end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end


  test "it should report a violation 1" do
"""
defmodule CredoSampleModule do
  def fun1 do
    case xyz do
      fun2 -> fun2 # now the variable is used instead of the function
      %{something: foobar} -> foobar
    end
  end

  defmacro fun2 do
    42
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation 2" do
"""
defmodule CredoSampleModule do
  def fun1 do
    case xyz do
      x -> x
      %{something: fun2} -> foobar # now the variable is used instead of the function
    end
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
  def fun1(param1) do
    case param1 do
      fun2 -> 5 # now the variable is used instead of the function
      _ -> 6
    end
  end

  def fun2 do
    42
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

end
