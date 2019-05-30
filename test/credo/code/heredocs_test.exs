defmodule Credo.Code.HeredocsTest do
  use Credo.TestHelper

  alias Credo.Code.Heredocs

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

    expected =
      """
      @moduledoc \"\"\"
      @@EMPTY_STRING@@
      \"\"\"

      x = ~s{also: # TODO: no comment here}
      ?" # TODO: this is the third
      # "

      "also: # TODO: no comment here as well"
      """
      |> String.replace(
        "@@EMPTY_STRING@@",
        "                                                        "
      )

    assert expected == source |> Heredocs.replace_with_spaces()
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

    result = source |> Heredocs.replace_with_spaces()
    assert source != result
    assert String.length(source) == String.length(result)
    refute String.contains?(result, "example")
    refute String.contains?(result, "TODO:")
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

    assert source == source |> Heredocs.replace_with_spaces()
  end

  test "it should return the source without string sigils and replace the contents" do
    source = """
    t = ~S\"\"\"
    abc
    \"\"\"
    """

    expected = """
    t = ~S\"\"\"
    ...
    \"\"\"
    """

    result = source |> Heredocs.replace_with_spaces(".")
    assert expected == result
  end

  test "it should return the source without the strings and replace the contents" do
    source = """
    t = ~S\"\"\"
    abc
    \"\"\"
    """

    expected = """
    t = ~S\"\"\"
    ...
    \"\"\"
    """

    result = source |> Heredocs.replace_with_spaces(".")
    assert expected == result
  end

  test "it should NOT report expected code /2" do
    source = ~S"""
    defmodule CredoSampleModule do
      def escape_subsection(""), do: "\"\""

      def escape_subsection(x) when is_binary(x) do
        x
        |> String.to_charlist()
        |> escape_subsection_impl([])
        |> Enum.reverse()
        |> to_quoted_string()
      end

      defp to_quoted_string(s), do: ~s["test string"]

      # git-config(1) lists the limited set of supported escape sequences
      # (which is even more limited for subsection names than for values).

      defp escape_subsection_impl([], reversed_result), do: reversed_result

      defp escape_subsection_impl([0 | _], _reversed_result),
        do: raise(ConfigInvalidError, "config subsection name contains byte 0x00")

      defp escape_subsection_impl([?\n | _], _reversed_result),
        do: raise(ConfigInvalidError, "config subsection name contains newline")

      defp escape_subsection_impl([c | remainder], reversed_result)
           when c == ?\\ or c == ?",
           do: escape_subsection_impl(remainder, [c | [?\\ | reversed_result]])

      defp escape_subsection_impl([c | remainder], reversed_result),
        do: escape_subsection_impl(remainder, [c | reversed_result])

    end
    """

    expected = source

    assert expected == Heredocs.replace_with_spaces(source)
  end

  test "it should return the source without string sigils and replace the contents including interpolation" do
    source = """
    def fun() do
      a = \"\"\"
      MyModule.\#{fun(Module.value() + 1)}.SubModule.\#{name}"
      \"\"\"
    end
    """

    expected = """
    def fun() do
      a = \"\"\"
    ........................................................
    ..\"\"\"
    end
    """

    result = source |> Heredocs.replace_with_spaces(".")
    assert expected == result
  end

  test "it should not modify commented out code" do
    source = """
    defmodule Foo do
      defmodule Bar do
        # @doc \"\"\"
        # Reassign a student to a discussion group.
        # This will un-assign student from the current discussion group
        # \"\"\"
        # def assign_group(leader = %User{}, student = %User{}) do
        #   cond do
        #     leader.role == :student ->
        #       {:error, :invalid}
        #
        #     student.role != :student ->
        #       {:error, :invalid}
        #
        #     true ->
        #       Repo.transaction(fn ->
        #         {:ok, _} = unassign_group(student)
        #
        #         %Group{}
        #         |> Group.changeset(%{})
        #         |> put_assoc(:leader, leader)
        #         |> put_assoc(:student, student)
        #         |> Repo.insert!()
        #       end)
        #   end
        # end
        def baz, do: 123
      end
    end
    """

    expected = source

    assert expected == source |> Heredocs.replace_with_spaces(".")
  end

  test "it should overwrite whitespace in heredocs" do
    source =
      """
      defmodule CredoSampleModule do
        @doc '''
        Foo++
        Bar
        '''
      end
      """
      |> String.replace("++", "  ")

    expected = """
    defmodule CredoSampleModule do
      @doc '''
    .......
    .....
    ..'''
    end
    """

    assert expected == source |> Heredocs.replace_with_spaces(".")
  end

  @example_code File.read!("test/fixtures/example_code/clean_redux.ex")
  test "it should produce valid code" do
    result = Heredocs.replace_with_spaces(@example_code)
    result2 = Heredocs.replace_with_spaces(result)

    assert result == result2, "Heredocs.replace_with_spaces/2 should be idempotent"
    assert match?({:ok, _}, Code.string_to_quoted(result))
  end
end
