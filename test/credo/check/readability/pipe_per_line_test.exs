defmodule Credo.Check.Readability.PipePerLineTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.PipePerLine

  test "it should NOT report the expected code" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun do
        some_val
        |> do_something()
        |> do_something_else()
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "reports a violation that includes rejected module attrs" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun do
        some_val |> do_something() |> do_something_else()
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "reports multiple violations when having multiples pipes" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun do
        some_val |> do_something() |> do_something_else()
        1 |> baz() |> bar()
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issues()
  end
end
