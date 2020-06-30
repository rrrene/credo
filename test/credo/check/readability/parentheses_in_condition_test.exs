defmodule Credo.Check.Readability.ParenthesesInConditionTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.ParenthesesInCondition

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        unless allowed? do
          something
        end

        if File.exists?(filename) do
          something
        else
          something_else
        end
        if !allowed? || (something_in_parentheses == 42) do
          something
        end
        if (something_in_parentheses == 42) || !allowed? do
          something
        end
        if !allowed? == (something_in_parentheses == 42) do
          something
        end
        unless (something_in_parentheses != 42) || allowed? do
          something
        end
        boolean |> if(do: :ok, else: :error)
        boolean |> unless(do: :ok)
        if(allowed_keyword?(a) || measured_unit?(a), do: a, else: "")
        if (thing && other_thing) || better_thing, do: something
        if !better_thing && (thing || other_thing), do: something_else
      end

      import Bitwise

    	def bar(foo, bar) do
    		if (foo &&& 0b1000) > 0, do: bar, else: nil
    	end

    	def foobar(foo) do
    		foo
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report expected code /2" do
    """
    props =
      if(valid?(username), do: [:authorized]) ++
      unless(admin?(username), do: [:restricted])
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report expected code /3" do
    """
    if (assocs != [] or prepare != []) and
       Keyword.get(opts, :skip_transaction) != true and
       function_exported?(adapter, :transaction, 3) do
      some_fun()
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report expected code /4" do
    """
    defmodule Foo do
      def bar(a, b) do
        if (a + b) / 100 > threshold(), do: :high, else: :low
        if (a + b) * 100 > threshold(), do: :high, else: :low
        if (a + b) + 100 > threshold(), do: :high, else: :low
        if (a + b) - 100 > threshold(), do: :high, else: :low
        if (a + b) &&& 100 > threshold(), do: :high, else: :low
      end
      def threshold, do: 50
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
    defmodule Mix.Tasks.Credo do
      def run(argv) do
        if( allowed? ) do
          true
        else
          false
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report violations with oneliners if used with parentheses" do
    """
    defmodule Mix.Tasks.Credo do
      def run(argv) do
        if (allowed?), do: true
        unless (!allowed?), do: true
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues()
  end

  test "it should report a violation if used with parentheses" do
    """
    defmodule Mix.Tasks.Credo do
      def run(argv) do
        unless( !allowed? ) do
          true
        else
          false
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report violations with spaces before the parentheses" do
    """
    defmodule Mix.Tasks.Credo do
      def run(argv) do
        if ( allowed? ) do
          true
        else
          false
        end

        unless (also_allowed?) do
          true
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues()
  end
end
