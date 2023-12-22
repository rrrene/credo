defmodule Credo.Code.SigilsTest do
  use Credo.Test.Case

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
    '~S( i am not a sigil! )'
    \"\"\"
    ~S( i am not a sigil! )
    \"\"\"
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
    '~S( i am not a sigil! )'
    \"\"\"
    ~S( i am not a sigil! )
    \"\"\"
    """

    result = Sigils.replace_with_spaces(source)
    assert expected == result
  end

  test "it should return the source without string literals 4" do
    source = """
    x = Regex.match?(~r/^\\d{1,2}\\/\\d{1,2}\\/\\d{4}$/, value)
    """

    expected = """
    x = Regex.match?(~r/                         /, value)
    """

    result = Sigils.replace_with_spaces(source)
    assert expected == result
  end

  test "it should return the source without string literals 5" do
    source = """
    x = Regex.match?(~r/\\"/, value)
    ~r{<>:"/\\\\\\?\\*}
    """

    expected = """
    x = Regex.match?(~r/  /, value)
    ~r{           }
    """

    result = Sigils.replace_with_spaces(source)
    assert expected == result
  end

  test "it should not crash and burn" do
    source = """
    defmodule Credo.CLI.Command.List do
      defp print_help do
        '\\'this is a charlist!'
        x = ~w(remove me)
        \"\"\"
        Arrows (↑ ↗ → ↘ ↓) hint at the importance of the object being looked at.
        \"\"\"
        |> UI.puts
        # ↑
        # ~r/abc/
      end
    end
    """

    expected = """
    defmodule Credo.CLI.Command.List do
      defp print_help do
        '\\'this is a charlist!'
        x = ~w(         )
        \"\"\"
        Arrows (↑ ↗ → ↘ ↓) hint at the importance of the object being looked at.
        \"\"\"
        |> UI.puts
        # ↑
        # ~r/abc/
      end
    end
    """

    result = Sigils.replace_with_spaces(source)
    assert expected == result
  end

  test "it should remove sigils with interpolation 2" do
    source = ~S"""
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        values = ~s{ #{"}"} }
      end
    end
    """

    expected = """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        values = ~s{}
      end
    end
    """

    assert expected == source |> Sigils.replace_with_spaces("")
  end

  test "it should remove sigils with interpolation 222" do
    source = ~S"""
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        values = ~s{ #{"x"} }
      end
    end
    """

    expected = """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        values = ~s{}
      end
    end
    """

    assert expected == source |> Sigils.replace_with_spaces("")
  end

  test "it should remove sigils with interpolation 3" do
    source = ~S"""
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        values = ~s{(#{Enum.map_join(fields, ", ", &quote_name/1)}) } <>
                 ~s{VALUES (#{Enum.map_join(1..length(fields), ", ", fn (_) -> "?" end)})}
      end
    end
    """

    expected = """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        values = ~s{} <>
                 ~s{}
      end
    end
    """

    assert expected == source |> Sigils.replace_with_spaces("")
  end

  @tag :to_be_implemented
  test "it should NOT replace interpolations in strings" do
    source = ~S"""
    def foo(a) do
      "#{a} #{a}"
    end

    def bar do
      " )"
    end
    """

    expected = ~S"""
    def foo(a) do
      "#{a} #{a}"
    end

    def bar do
      " )"
    end
    """

    assert expected == Sigils.replace_with_spaces(source, "")
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

    assert expected == Sigils.replace_with_spaces(source, "")
  end

  test "it should not heredocs" do
    source = ~S'''
    test "some test case" do
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
    '''

    result = Sigils.replace_with_spaces(source)
    result2 = Sigils.replace_with_spaces(result)

    assert match?({:ok, _}, Code.string_to_quoted(result)),
           "Sigils.replace_with_spaces/2 should produce valid code"

    assert result == result2, "Sigils.replace_with_spaces/2 should be idempotent"
  end

  @tag slow: :disk_io
  test "it should produce valid code /2" do
    example_code = File.read!("test/fixtures/example_code/nested_escaped_heredocs.ex")
    result = Sigils.replace_with_spaces(example_code)
    result2 = Sigils.replace_with_spaces(result)

    assert match?({:ok, _}, Code.string_to_quoted(result)),
           "Sigils.replace_with_spaces/2 should produce valid code"

    assert result == result2, "Sigils.replace_with_spaces/2 should be idempotent"
  end

  @tag slow: :disk_io
  test "it should produce valid code /5" do
    example_code = File.read!("test/fixtures/example_code/browser.ex")

    result =
      example_code
      |> to_source_file()
      |> Sigils.replace_with_spaces(".", ".")

    result2 =
      result
      |> Sigils.replace_with_spaces(".", ".")

    assert match?({:ok, _}, Code.string_to_quoted(result)),
           "Sigils.replace_with_spaces/2 should produce valid code"

    assert result == result2, "Sigils.replace_with_spaces/2 should be idempotent"
  end

  test "it should produce valid code /7" do
    source = ~S"""
    String.replace(string, ~r{<>:"/\\\?\*}, "")
    """

    expected = ~S"""
    String.replace(string, ~r{           }, "")
    """

    result = Sigils.replace_with_spaces(source)
    result2 = Sigils.replace_with_spaces(result)

    assert result == expected
    assert result == result2, "Sigils.replace_with_spaces/2 should be idempotent"
    assert match?({:ok, _}, Code.string_to_quoted(result))
  end

  test "it should not replace the remaining contents of the file with whitespace" do
    source = "
    ~F\"\"\"
    \"\"\"

    :ok
    "

    expected = "
    ~F\"\"\"
    \"\"\"

    :ok
    "

    result = Sigils.replace_with_spaces(source)
    assert result == expected
    assert match?({:ok, _}, Code.string_to_quoted(result))
  end

  test "it should NOT report expected code with multiline strings" do
    input = ~S"""
    foo = ~x'
    a


    b
    '
    """

    expected = ~S"""
    foo = ~x'
    .
    .
    .
    .
    '
    """

    assert expected ==
             Sigils.replace_with_spaces(
               input,
               ".",
               ".",
               "nofilename",
               "."
             )
  end

  test "it should NOT report expected code with multiline string sigils" do
    input = ~S"""
    foo = ~H"
    a


    b
    "
    """

    expected = ~S"""
    foo = ~H"
    .
    .
    .
    .
    "
    """

    assert expected ==
             Sigils.replace_with_spaces(
               input,
               ".",
               ".",
               "nofilename",
               "."
             )
  end
end
