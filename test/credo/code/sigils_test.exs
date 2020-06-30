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

    result = source |> Sigils.replace_with_spaces()
    assert expected == result
  end

  test "it should return the source without string literals 4" do
    source = """
    x = Regex.match?(~r/^\\d{1,2}\\/\\d{1,2}\\/\\d{4}$/, value)
    """

    expected = """
    x = Regex.match?(~r/                         /, value)
    """

    result = source |> Sigils.replace_with_spaces()
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
        # ~r/abc/
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
        # ~r/abc/
      end
    end
    """

    result = source |> Sigils.replace_with_spaces()
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

  @tag slow: :disk_io
  test "it should produce valid code /2" do
    example_code = File.read!("test/fixtures/example_code/nested_escaped_heredocs.ex")
    result = Sigils.replace_with_spaces(example_code)
    result2 = Sigils.replace_with_spaces(result)

    assert result == result2, "Sigils.replace_with_spaces/2 should be idempotent"
    assert match?({:ok, _}, Code.string_to_quoted(result))
  end
end
