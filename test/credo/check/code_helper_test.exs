defmodule Credo.Check.CodeHelperTest do
  use Credo.TestHelper

  alias Credo.Check.CodeHelper

  test "it should return true" do
    parent = {{:., [line: 5], [{:__aliases__, [counter: 0, line: 5], [:String]}, :split]},
              [line: 5], [{:parameter1, [line: 5], nil}]}
    child = {:parameter1, [line: 5], nil}

    assert CodeHelper.contains_child?(parent, child)
  end

  test "it should return the function name" do
    ast = """
    defp foobar(v) do
      List.wrap(v)
      something
    end
    """ |> Code.string_to_quoted!

    assert :foobar == CodeHelper.def_name(ast)

    ast = """
    defp foobar(v), do: List.wrap(v)
    """ |> Code.string_to_quoted!

    assert :foobar == CodeHelper.def_name(ast)

    ast = """
    defp foobar(v) when is_atom(v) or is_nil(v), do: List.wrap(v)
    """ |> Code.string_to_quoted!

    assert :foobar == CodeHelper.def_name(ast)
  end

  test "it should NOT report expected code" do
    expected = "defmodule CredoSampleModule do\n  def some_function(parameter1, parameter2) do\n    parameter1 + \"                 \" \n  end\nend\n"
    source_file = """
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    parameter1 + " this is a string" # WARNING: NÃO ESTÁ A FUNCIONAR
  end
end
""" |> to_source_file
    assert expected == source_file |> CodeHelper.clean_strings_sigils_and_comments
  end

  test "it should NOT report expected code 2" do
    expected = "defmodule CredoSampleModule do\n  def some_function(parameter1, parameter2) do\n    parameter1 + \"                 \"\n  end\nend\n"
    source_file = """
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    parameter1 + " this is a string"# tell the most browser´s to open
  end
end
""" |> to_source_file
    assert expected == source_file |> CodeHelper.clean_strings_sigils_and_comments
  end

end
