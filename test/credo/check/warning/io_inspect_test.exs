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
    |> assert_issue(%{line_no: 3, trigger: "IO.inspect"})
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
    |> assert_issues(2)
    |> assert_issues_match([
      %{line_no: 3, column: 9},
      %{line_no: 3, column: 48}
    ])
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
    |> assert_issue(%{line_no: 4, trigger: "IO.inspect"})
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
