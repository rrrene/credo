defmodule Credo.Code.CharlistsTest do
  use Credo.Test.Case

  alias Credo.Code.Charlists

  test "it should return the source unchanged if there are no charlists" do
    source = ~S'''
    "it should report a violation if the with doesn't start with <- clauses"
    """
    def some_function(parameter1, parameter2) do
      with IO.puts("not a <- clause"),
           :ok <- parameter1 do
        parameter2
      end
    end
    """
    ~s("with" doesn't start with a <- clause)
    '''

    assert source == Charlists.replace_with_spaces(source)
  end

  test "it should return the source without string literals 2" do
    source = ~S'''
    x = "this 'should not be' removed!"
    y = 'also: # TODO: no comment here'
    ?' # TODO: this is the third
    # '

    """
    inside_heredoc = 'also: # TODO: no comment here'
    """

    'also: # TODO: no comment here as well'
    '''

    expected = ~S'''
    x = "this 'should not be' removed!"
    y = '                             '
    ?' # TODO: this is the third
    # '

    """
    inside_heredoc = 'also: # TODO: no comment here'
    """

    '                                     '
    '''

    assert expected == source |> Charlists.replace_with_spaces()
  end

  test "it should not modify commented out code" do
    source = ~S'''
    defmodule Foo do
      defmodule Bar do
        # @doc """
        # Reassign a student to a discussion group.
        # This will un-assign student from the current discussion group
        # """
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
    '''

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

  @tag slow: :disk_io
  test "it should produce valid code /5" do
    example_code = File.read!("test/fixtures/example_code/browser.ex")

    result =
      example_code
      |> to_source_file()
      |> Charlists.replace_with_spaces(".", ".")

    result2 =
      result
      |> Charlists.replace_with_spaces(".", ".")

    if not match?({:ok, _}, Code.string_to_quoted(result)) do
      IO.puts(result)
    end

    assert match?({:ok, _}, Code.string_to_quoted(result)),
           "Charlists.replace_with_spaces/2 should produce valid code #{inspect(Code.string_to_quoted(result))}"

    assert result == result2, "Charlists.replace_with_spaces/2 should be idempotent"
  end

  test "it should NOT report expected code with multiline strings" do
    input = ~S'''
    foo = '
    a


    b
    '
    '''

    expected = ~S'''
    foo = '
    .
    .
    .
    .
    '
    '''

    assert expected ==
             Charlists.replace_with_spaces(
               input,
               ".",
               ".",
               "nofilename",
               "."
             )
  end

  test "it should NOT report expected code with multiline string sigils" do
    input = ~S'''
    foo = ~c"
    a


    b
    "
    '''

    expected = ~S'''
    foo = ~c"
    .
    .
    .
    .
    "
    '''

    assert expected ==
             Charlists.replace_with_spaces(
               input,
               ".",
               ".",
               "nofilename",
               "."
             )
  end
end
