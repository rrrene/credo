defmodule Credo.Check.Refactor.NegatedIsNilTest do
  use Credo.Test.Case

  @described_check Credo.Check.Refactor.NegatedIsNil

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, nil) do
        something
      end
      def some_function(parameter1, parameter2) do
        something
      end
      # `is_nil` in guard still works
      def common_guard(%{a: a, b: b}) when is_nil(b) do
        something
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation - `not is_nil is not part of a guard clause`" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(%{parameter1: parameter2, id: id}) when is_binary(parameter2) do
        something = not is_nil(parameter2)
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation - ` !is_nil is not part of a guard clause`" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(%{parameter1: parameter2, id: id}) when is_binary(parameter2) do
        something = !is_nil(parameter2)
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

  test "it should report a violation - `when not is_nil`" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) when not is_nil(parameter2) do
        something
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation - `when !is_nil`" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) when !is_nil(parameter2) do
        something
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation - `when not is_nil is part of a multi clause guard`" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(%{parameter1: parameter2, id: id}) when not is_nil(parameter2) and is_binary(parameter2) do
        something
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation - `when !is_nil is part of a multi clause guard`" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(%{parameter1: parameter2, id: id}) when !is_nil(parameter2) and is_binary(parameter2) do
        something
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.line_no == 2
      assert issue.trigger == "!"
    end)
  end

  test "it should report only one violation in a module with multiple functions when only one is problematic" do
    ~S'''
    defmodule CredoSampleModule do
      def hello(a) when not is_nil(a), do: a
      def foo1(x) when is_integer(x), do: x
      def foo2(x) when is_integer(x), do: x
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.line_no == 2
      assert issue.trigger == "not"
    end)
  end

  test "it should report two violations in a module with multiple functions when two are problematic" do
    ~S'''
    defmodule CredoSampleModule do
      def hello(a) when not is_nil(a), do: a
      def foo1(x) when is_integer(x), do: x
      def foo2(x) when is_integer(x), do: x
      def hello2(a) when not is_nil(a), do: a
      def foo3(x) when is_integer(x), do: x
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issues(fn issues -> assert length(issues) == 2 end)
  end
end
