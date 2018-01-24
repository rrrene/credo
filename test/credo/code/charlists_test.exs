defmodule Credo.Code.CharlistsTest do
  use Credo.TestHelper

  alias Credo.Code.Charlists

  test "it should return the source without string literals 2" do
    source = """
    x = "this 'should not be' removed!"
    y = 'also: # TODO: no comment here'
    ?' # TODO: this is the third
    # '

    \"\"\"
    y = 'also: # TODO: no comment here'
    \"\"\"

    'also: # TODO: no comment here as well'
    """

    expected = """
    x = "this 'should not be' removed!"
    y = '                             '
    ?' # TODO: this is the third
    # '

    \"\"\"
    y = 'also: # TODO: no comment here'
    \"\"\"

    '                                     '
    """

    assert expected == source |> Charlists.replace_with_spaces()
  end
end
