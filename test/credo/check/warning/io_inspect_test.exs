defmodule Credo.Check.Warning.IoInspectTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.IoInspect

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        parameter1 + parameter2
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report Inspect/3" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1) do
        IO.inspect(:stderr, parameter1, [])
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        IO.inspect parameter1 + parameter2
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation with two on the same line" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        foo(IO.inspect(parameter1), parameter2) |> IO.inspect()
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues(fn [first, second] ->
      assert first.line_no == 3
      assert first.column == 48

      assert second.line_no == 3
      assert second.column == 9
    end)
  end

  test "it should report a violation /2" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        parameter1 + parameter2
        |> IO.inspect
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.line_no == 4
      assert issue.trigger == "IO.inspect"
    end)
  end

  test "it should report a violation /3" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(a, b, c) do
        map([a,b,c], &IO.inspect(&1))
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
        Elixir.IO.inspect parameter1 + parameter2
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end
end
