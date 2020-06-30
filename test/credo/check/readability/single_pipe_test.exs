defmodule Credo.Check.Readability.SinglePipeTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.SinglePipe

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun do
        some_val
        |> do_something
        |> do_something_else
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun do
        some_val |> do_something
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation for multiple violations" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun do
        some_val |> do_something
        some_other_val
        |> do_something
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues()
  end
end
