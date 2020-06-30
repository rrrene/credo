defmodule Credo.Check.Refactor.RegexEmptyCharacterClassesTest do
  use Credo.Test.Case

  @described_check Credo.Check.Refactor.RegexEmptyCharacterClasses

  @moduletag :to_be_implemented

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      def my_fun do
        ~r/^foo[a-z]/ |> Regex.run("foobar")
          "^foo[]"
          |> Regex.compile!
          |> Regex.run("foobar")
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report expected code /2" do
    """
    defmodule CredoSampleModule do
      def my_fun do
        "^foo[a-z]"
        |> Regex.compile!
        |> Regex.run("foobar")
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
      def some_function(parameter1, parameter2) do
        regex = ~r/^foo[]/
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /2" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        "^foo[]"
        |> Regex.compile!
        |> Regex.run("foobar")
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /3" do
    """
    defmodule CredoSampleModule do
      @some_value "^foo[]"
      def some_function(parameter1, parameter2) do
        regex = Regex.compile!(@some_value)

        Regex.run(regex, "foobar")
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end
end
