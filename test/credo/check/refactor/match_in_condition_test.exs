defmodule Credo.Check.Refactor.MatchInConditionTest do
  use Credo.Test.Case

  @described_check Credo.Check.Refactor.MatchInCondition

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        # comparison should not affect this check in any way
        if parameter1 == parameter2 do
          do_something
        end
        # simple wildcard matches/variable assignment should not affect this check
        if parameter1 = Regex.run(~r/\d+/, parameter2) do
          do_something
        end
        # simple wildcard wrapped in parens
        if( parameter1 = foo(bar) ) do
          do_something
        end

        # no match in parens
        if String.match?(name, ~r/^[a-z]/) do
          mod_name = names |> Enum.slice(0..length(names) - 2) |> Enum.join(".")
          mod_prio = lookup[mod_name]
          {scope_name, prio + mod_prio}
        else
          {scope_name, prio}
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should not crash with ecto query" do
    """
    defmodule CredoSampleModule do

      def some_function(parameter1) do
        query = from if in FooInterface,
                 join: is in assoc(if, :instance),
                 join: d in assoc(if, :device),
                 where: fragment("upper(?->>'foo_id') = ?", if.opts, ^parameter1) and is.driver == ^"FooBar",
                 preload: [device: d, instance: is]

        Repo.all(query)
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
        if {:ok, value} = parameter1 do
          do_something
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation 2" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        if String.match?(name, ~r/^[a-z]/) do
          mod_name = names |> Enum.slice(0..length(names) - 2) |> Enum.join(".")
          mod_prio = lookup[mod_name]
          if {:ok, value} = parameter1 do         # <-- this one should be found
            do_something
          end
        else
          {scope_name, prio}
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation when wrapped in parens" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        if( {:ok, value} = parameter1 ) do
          do_something
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation for :unless" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        unless {:ok, value} = parameter1 do
          do_something
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation for :if with nested match" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        if !is_nil(baz = Map.get(foo, :bar)), do: baz
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation for :if with nested match /2" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        if allowed? && !is_nil(baz = Map.get(foo, :bar)) do
          baz
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation for :unless with nested match" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        unless !(x = Map.get(foo, :bar)), do: x
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end
end
