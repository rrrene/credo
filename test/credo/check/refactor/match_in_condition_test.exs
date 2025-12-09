defmodule Credo.Check.Refactor.MatchInConditionTest do
  use Credo.Test.Case

  @described_check Credo.Check.Refactor.MatchInCondition

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    ~S'''
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
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report nor crash with ecto query" do
    ~S'''
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
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report bracket access" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1) do
        if token = cookies[@remember_me_cookie] do
          # ...
        end
        if token = cookies[:remember_me] do
          # ...
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation with :allow_tagged_tuples" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        if {:foo, value} = parameter1 do
          do_something
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, allow_tagged_tuples: true)
    |> refute_issues()
  end

  test "it should NOT report a violation for operators in simple assignments with :allow_operators" do
    """
    defmodule CredoSampleModule do
      def some_function(foo, parameter2) do
        if baz = Map.get(foo, :bar) || parameter2 do
          baz
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check, allow_operators: true)
    |> refute_issues()
  end

  test "it should NOT report a violation for operators in function calls with :allow_operators" do
    """
    defmodule CredoSampleModule do
      def some_function(foo, parameter2) do
        if baz = allowed?(foo[:bar] ++ parameter2) do
          baz
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check, allow_operators: true)
    |> refute_issues()
  end

  test "it should NOT report a violation for operators in function calls with :allow_operators /2" do
    """
    defmodule CredoSampleModule do
      def some_function(foo, parameter2) do
        if baz = allowed?(Map.get(foo, :bar) &&& parameter2) do
          baz
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check, allow_operators: true)
    |> refute_issues()
  end

  test "it should NOT report a violation for operators in function calls with :allow_operators /3" do
    """
    defmodule CredoSampleModule do
      def some_function(foo, parameter2) do
        if value = map |> Map.get(key) do
          value
        else
          default
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check, allow_operators: true)
    |> refute_issues()
  end

  test "it should NOT report a violation for operators in function calls with :allow_operators /4" do
    """
    defmodule CredoSampleModule do
      def some_function(foo, parameter2) do
        if contents = File.read(input <> \".txt\") do
          value
        else
          default
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check, allow_operators: true)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        if {:ok, value} = parameter1 do
          do_something
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /2" do
    ~S'''
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
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /3" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        if condition? && {:ok, value} = parameter1 do
          do_something
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /4" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        if (contents = parameter1.contents) && parameter2 do
          do_something()
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /5" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        if contents = parameter1.contents && parameter2 do
          do_something()
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /6" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(a, b) do
        if foo = bar(a && b) do
          do_something()
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation when wrapped in parens" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        if( {:ok, value} = parameter1 ) do
          do_something
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation for :unless" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        unless {:ok, value} = parameter1 do
          do_something
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation for :if with nested match" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        if !is_nil(baz = Map.get(foo, :bar)), do: baz
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation for :if with nested match /2" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        if allowed? && !is_nil(baz = Map.get(foo, :bar)) do
          baz
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation for :unless with nested match" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        unless !(x = Map.get(foo, :bar)), do: x
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.line_no == 3
      assert issue.trigger == "="
    end)
  end

  test "it should report a violation for operators in simple assignments" do
    """
    defmodule CredoSampleModule do
      def some_function(foo, parameter2) do
        if baz = Map.get(foo, :bar) || parameter2 do
          baz
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation for operators in function calls" do
    """
    defmodule CredoSampleModule do
      def some_function(foo, parameter2) do
        if baz = allowed?(foo[:bar] ++ parameter2) do
          baz
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation for operators in function calls /2" do
    """
    defmodule CredoSampleModule do
      def some_function(foo, parameter2) do
        if baz = allowed?(Map.get(foo, :bar) &&& parameter2) do
          baz
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation for operators in function calls /3" do
    """
    defmodule CredoSampleModule do
      def some_function(foo, parameter2) do
        if value = map |> Map.get(key) do
          value
        else
          default
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation for operators in function calls /4" do
    """
    defmodule CredoSampleModule do
      def some_function(foo, parameter2) do
        if contents = File.read(input <> \".txt\") do
          value
        else
          default
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end
end
