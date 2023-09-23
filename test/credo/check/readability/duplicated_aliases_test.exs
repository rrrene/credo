defmodule Credo.Check.Readability.DuplicatedAliasesTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.DuplicatedAliases

  test "should raise an issue for duplicated aliases" do
    file = """
    defmodule M1 do
      alias URI
      alias URI
    end
    """

    file
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "should raise an issue for duplicated nested aliases" do
    file = """
    defmodule M1 do
      alias IO.ANSI
      alias IO.ANSI
    end
    """

    file
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "should raise an issue if duplicated alias in function" do
    file = """
    defmodule M1 do
      alias IO.ANSI

      def test do
        alias IO.ANSI

        :ok
      end
    end
    """

    file
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end
end
