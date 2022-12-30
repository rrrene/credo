defmodule Credo.Check.Readability.OnePipePerLineTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.OnePipePerLine

  test "it should NOT report the expected code" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun do
        1
        |> Integer.to_string()
        |> String.to_integer()
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
        1 |> Integer.to_string() |> String.to_integer()
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
        "1" |> String.to_integer() |> Integer.to_string()
        1 |> Integer.to_string() |> String.to_integer()
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issues()
  end
end
