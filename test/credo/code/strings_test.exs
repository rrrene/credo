defmodule Credo.Code.StringsTest do
  use Credo.TestHelper

  alias Credo.Code.Strings

  test "it should return the source without string literals 2" do
    source = """
@moduledoc \"\"\"
this is an example # TODO: and this is no actual comment
\"\"\"

x = ~s{also: # TODO: no comment here}
?" # TODO: this is the third
# "

"also: # TODO: no comment here as well"
"""
    expected = """
@moduledoc \"\"\"
@@EMPTY_STRING@@
\"\"\"

x = ~s{                             }
?" # TODO: this is the third
# "

"                                     "
""" |> String.replace("@@EMPTY_STRING@@",
                  "                                                        ")
    assert expected == source |> Strings.replace_with_spaces
  end

  test "it should return the source without string sigils 2" do
    source = """
  should "not error for a quote in a heredoc" do
    errors = ~s(
    \"\"\"
this is an example " TODO: and this is no actual comment
    \"\"\") |> lint
    assert [] == errors
  end
"""
    result = source |> Strings.replace_with_spaces
    assert source != result
    assert String.length(source) == String.length(result)
    refute String.contains?(result, "example")
    refute String.contains?(result, "TODO:")
  end

  test "it should return the source without string sigils 3" do
    source = ~S"""
    def gen_name(name) when is_binary(name),
      do: "#{String.replace_suffix(name, "-test", "")}_name"
    """
    expected = ~S"""
    def gen_name(name) when is_binary(name),
      do: "                                                "
    """

    assert expected == Strings.replace_with_spaces(source)
  end

  test "it should return the source without string literals 3" do
    source = """
x =   "↑ ↗ →"
x = ~s|text|
x = ~s"text"
x = ~s'text'
x = ~s(text)
x = ~s[text]
x = ~s{text}
x = ~s<text>
x = ~S|text|
x = ~S"text"
x = ~S'text'
x = ~S(text)
x = ~S[text]
x = ~S{text}
x = ~S<text>
?" # <-- this is not a string
"""
    expected = """
x =   "     "
x = ~s|    |
x = ~s"    "
x = ~s'    '
x = ~s(    )
x = ~s[    ]
x = ~s{    }
x = ~s<    >
x = ~S|    |
x = ~S"    "
x = ~S'    '
x = ~S(    )
x = ~S[    ]
x = ~S{    }
x = ~S<    >
?" # <-- this is not a string
"""
    assert expected == source |> Strings.replace_with_spaces
  end

  test "it should return the source without string sigils and replace the contents" do
    source = """
t = ~s({
})
"""
    expected = """
t = ~s(.
.)
"""
    result = source |> Strings.replace_with_spaces(".")
    assert expected == result
  end
end
