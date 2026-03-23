defmodule Credo.Check.Readability.CaptureOperatorTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.CaptureOperator

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    ~S'''
    defmodule CredoSampleModule do
      def some_fun do
        y = & &1
        Enum.map(x, fn value -> value.node_name end)
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report expected code with param :allow_field_access" do
    ~S'''
    defmodule CredoSampleModule do
      def some_fun do
        Enum.map(x, & &1.name)
        Enum.map(x, & &1[:level])
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, allow_field_access: true)
    |> refute_issues()
  end

  test "it should NOT report expected code with param :allow_function_with_arity" do
    ~S'''
    defmodule CredoSampleModule do
      def some_fun do
        Enum.map(x, &String.downcase/1)
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, allow_function_with_arity: true)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation for a simple capture accessing a field via dot syntax" do
    ~S'''
    defmodule CredoSampleModule do
      def some_fun do
        Enum.map(x, & &1.name)
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(%{trigger: "&", line_no: 3, column: 17})
  end

  test "it should report a violation for a simple capture accessing a field via access syntax" do
    ~S'''
    defmodule CredoSampleModule do
      def some_fun do
        Enum.map(x, & &1[:level])
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation for a capture with arity" do
    ~S'''
    defmodule CredoSampleModule do
      def some_fun do
        Enum.flat_map(x, &some_fun/1)
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation for a capture with module and arity" do
    ~S'''
    defmodule CredoSampleModule do
      def some_fun do
        Enum.flat_map(x, &SomeMod.some_fun/1)
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation for a capture with additional parameters" do
    ~S'''
    defmodule CredoSampleModule do
      def some_fun do
        Enum.reduce(x, &some_fun(&1, &2, some_var))
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation for a capture constructing a tuple" do
    ~S'''
    defmodule CredoSampleModule do
      def some_fun do
        Enum.map(x, & {&1.nickname, &1.admin?})
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation for a capture constructing a list" do
    ~S'''
    defmodule CredoSampleModule do
      def some_fun do
        Enum.map(x, & [&1.login, &1.boss?])
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation for a capture of a function with arity" do
    ~S'''
    defmodule CredoSampleModule do
      def some_fun do
        Enum.map(x, &String.downcase/1)
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end
end
