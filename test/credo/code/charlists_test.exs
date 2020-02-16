defmodule Credo.Code.CharlistsTest do
  use Credo.Test.Case

  alias Credo.Code.Charlists

  test "it should return the source unchanged if there are no charlists" do
    source = """
    "it should report a violation if the with doesn't start with <- clauses"
    \"\"\"
    def some_function(parameter1, parameter2) do
      with IO.puts("not a <- clause"),
           :ok <- parameter1 do
        parameter2
      end
    end
    \"\"\"
    ~s("with" doesn't start with a <- clause)
    """

    assert source == Charlists.replace_with_spaces(source)
  end

  test "it should return the source without string literals 2" do
    source = """
    x = "this 'should not be' removed!"
    y = 'also: # TODO: no comment here'
    ?' # TODO: this is the third
    # '

    \"\"\"
    inside_heredoc = 'also: # TODO: no comment here'
    \"\"\"

    'also: # TODO: no comment here as well'
    """

    expected = """
    x = "this 'should not be' removed!"
    y = '                             '
    ?' # TODO: this is the third
    # '

    \"\"\"
    inside_heredoc = 'also: # TODO: no comment here'
    \"\"\"

    '                                     '
    """

    assert expected == source |> Charlists.replace_with_spaces()
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

    assert expected == source |> Charlists.replace_with_spaces(".")
  end

  @tag slow: :disk_io
  test "it should produce valid code /2" do
    example_code = File.read!("test/fixtures/example_code/nested_escaped_heredocs.ex")
    result = Charlists.replace_with_spaces(example_code)
    result2 = Charlists.replace_with_spaces(result)

    assert result == result2, "Charlists.replace_with_spaces/2 should be idempotent"
    assert match?({:ok, _}, Code.string_to_quoted(result))
  end
end
