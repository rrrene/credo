defmodule Credo.Check.Warning.OperationWithConstantResultTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.OperationWithConstantResult

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    ~S'''
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun do
        x * 2
        Enum.reject(some_list, &is_nil/1)
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report expected code with specs" do
    ~S'''
    defmodule CredoSampleModule do
      use ExUnit.Case

      @spec some() :: <<_::1, _::_*1>>
      def some(), do: <<1::1>>

      @spec other() :: <<_::_*1>>
      def other(), do: <<>>
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation for * 1" do
    ~S'''
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun do
        x * 1
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(%{trigger: "*"})
  end

  test "it should report a violation for all defined operations" do
    ~S'''
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun(x, y) do
        x * 1   # always returns x
        x * 0   # always returns 0
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues(2)
    |> assert_issues_match([
      %{line_no: 5, column: 7, trigger: "*"},
      %{line_no: 6, column: 7, trigger: "*"}
    ])
  end
end
