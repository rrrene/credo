defmodule Credo.Code.SigilsTest do
  use Credo.TestHelper

  alias Credo.Code.Sigils

  test "it should return the source without string literals 3" do
    source = """
x = ~c|a b c|
x = ~s"a b c"
x = ~r'a b c'
x = ~w(a b c)
x = ~c[a b c]
x = ~s{a b c}
x = ~r<a b c>
x = ~W|a b c|
x = ~C"a b c"
x = ~S'a b c'
x = ~R(a b c)
x = ~W[a b c]
x = ~C{a b c}
x = ~S<a b c>
"~S( i am not a sigil! )"
"""
    expected = """
x = ~c|     |
x = ~s"     "
x = ~r'     '
x = ~w(     )
x = ~c[     ]
x = ~s{     }
x = ~r<     >
x = ~W|     |
x = ~C"     "
x = ~S'     '
x = ~R(     )
x = ~W[     ]
x = ~C{     }
x = ~S<     >
"~S( i am not a sigil! )"
"""
    result = source |> Sigils.replace_with_spaces
    assert expected == result
  end

  test "it should return the source without string literals 4" do
    source = """
x = Regex.match?(~r/^\\d{1,2}\\/\\d{1,2}\\/\\d{4}$/, value)
"""
    expected = """
x = Regex.match?(~r/                         /, value)
"""
    result = source |> Sigils.replace_with_spaces
    assert expected == result
  end

  test "it should not crash and burn" do
    source = """
defmodule Credo.CLI.Command.List do
  defp print_help do
    x = ~w(remove me)
    \"\"\"
    Arrows (↑ ↗ → ↘ ↓) hint at the importance of the object being looked at.
    \"\"\"
    |> UI.puts
    # ↑
  end
end
"""
    expected = """
defmodule Credo.CLI.Command.List do
  defp print_help do
    x = ~w(         )
    \"\"\"
    Arrows (↑ ↗ → ↘ ↓) hint at the importance of the object being looked at.
    \"\"\"
    |> UI.puts
    # ↑
  end
end
"""
    result = source |> Sigils.replace_with_spaces
    assert expected == result
  end

  @tag :to_be_implemented
  test "it should remove sigils with interpolation 2" do
    expected = """
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    values = ~s{}
  end
end
"""
    source = ~S"""
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    values = ~s{ #{"}"} }
  end
end
"""
    assert expected == source |> Sigils.replace_with_spaces("")
  end

  @tag :to_be_implemented
  test "it should remove sigils with interpolation 3" do
    expected = """
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    values = ~s{} <>
             ~s{}
  end
end
"""
    source = ~S"""
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    values = ~s{(#{Enum.map_join(fields, ", ", &quote_name/1)}) } <>
             ~s{VALUES (#{Enum.map_join(1..length(fields), ", ", fn (_) -> "?" end)})}
  end
end
"""
    assert expected == source |> Sigils.replace_with_spaces("")
  end

end
