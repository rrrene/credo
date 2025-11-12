defmodule Credo.Check.Warning.UnsafeToAtomTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.UnsafeToAtom

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    ~S'''
    defmodule CredoSampleModule do
      @test_module_attribute String.to_atom("foo")
      @test_module_attribute2 Jason.decode("", keys: :atoms)

      def convert_module(parameter) do
        Module.safe_concat(__MODULE__, parameter)
      end

      def convert_module_2(parameter1, parameter2) do
        Module.safe_concat([__MODULE__, parameter1, parameter2])
      end

      def convert_atom(parameter) do
        String.to_existing_atom(parameter)
      end

      def convert_atom_2(parameter) do
        List.to_existing_atom(parameter)
      end

      def convert_erlang_list(parameter) do
        :erlang.list_to_existing_atom(parameter)
      end

      def convert_erlang_binary(parameter) do
        :erlang.binary_to_existing_atom(parameter, :utf8)

        unquote(context).unquote(:"get_#{type}_by")(id: id)
      end

      for n <- 1..4 do
        def unquote(:"fun_#{n}")(), do: unquote(n)
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  # Keys unspecified
  test "it should NOT report a violation on Jason.decode without keys with a pipeline" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter) do
        parameter |> Jason.decode()
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation on Jason.decode without keys without a pipeline" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter) do
        Jason.decode(parameter)
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation on Jason.decode! without keys with a pipeline" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter) do
        parameter |> Jason.decode!()
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation on Jason.decode! without keys without a pipeline" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter) do
        Jason.decode!(parameter)
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  # keys: :atoms! (safe)
  test "it should NOT report a violation on Jason.decode with keys: :atoms! with a pipeline" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter) do
        parameter |> Jason.decode(keys: :atoms!)
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation on Jason.decode with keys: :atoms! without a pipeline" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter) do
        Jason.decode(parameter, keys: :atoms!)
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation on Jason.decode! with keys: :atoms! with a pipeline" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter) do
        parameter |> Jason.decode!(keys: :atoms!)
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation on Jason.decode! with keys: :atoms! without a pipeline" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter) do
        Jason.decode!(parameter, keys: :atoms!)
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter) do
        String.to_atom(parameter)
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation (piped)" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter) do
        parameter
        |> String.to_atom()
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation (start of pipe)" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter) do
        String.to_atom(parameter)
        |> IO.inspect()
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /2" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter) do
        List.to_atom(parameter)
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /2 (piped)" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter) do
        parameter
        |> List.to_atom()
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /2 (start of pipe)" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter) do
        List.to_atom(parameter)
        |> IO.inspect()
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /3" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter) do
        Module.concat(__MODULE__, parameter)
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /3 (piped)" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter) do
        __MODULE__
        |> Module.concat(parameter)
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /3 (start of pipe)" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter) do
        Module.concat(__MODULE__, parameter)
        |> IO.inspect
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /4" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        Module.concat([__MODULE__, parameter1, parameter2])
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /5" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter) do
        :erlang.list_to_atom(parameter)
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /5 (piped)" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter) do
        parameter
        |> :erlang.list_to_atom()
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /5 (start of pipe)" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter) do
        :erlang.list_to_atom(parameter)
        |> IO.inspect()
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /6" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter) do
        :erlang.binary_to_atom(parameter, :utf8)
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /6 (piped)" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter) do
        parameter
        |> :erlang.binary_to_atom(:utf8)
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /6 (start of pipe)" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter) do
        :erlang.binary_to_atom(parameter, :utf8)
        |> IO.inspect()
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  # keys: :atoms (unsafe)
  test "it should report a violation on Jason.decode with keys: :atoms!with a pipeline" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter) do
        parameter |> Jason.decode(keys: :atoms)
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation on Jason.decode with keys: :atoms without a pipeline" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter) do
        Jason.decode(parameter, keys: :atoms)
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation on Jason.decode! with keys: :atoms with a pipeline" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter) do
        parameter |> Jason.decode!(keys: :atoms)
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation on Jason.decode! with keys: :atoms without a pipeline" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter) do
        Jason.decode!(parameter, keys: :atoms)
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.line_no == 3
      assert issue.trigger == "Jason.decode!"
    end)
  end
end
