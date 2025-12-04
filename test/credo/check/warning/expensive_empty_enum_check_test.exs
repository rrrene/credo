defmodule Credo.Check.Warning.ExpensiveEmptyEnumCheckTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.ExpensiveEmptyEnumCheck

  #
  # cases NOT raising issues
  #

  test "it should NOT report when when using length with non zero" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(some_list) do
        if length(some_list) == 2 do
          "has 2"
        else
          "something else"
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report when when using length with non zero backwards" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(some_list) do
        if 2 == length(some_list) do
          "has 2"
        else
          "something else"
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report when checking if Enum.count is non 0" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(enum) do
        if Enum.count(enum) == 3 do
          "has 3"
        else
          "something else"
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report when checking if Enum.count is non 0 backwards" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(enum) do
        if 3 == Enum.count(enum) do
          "has 3"
        else
          "something else"
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report when checking if a variable called length is 0" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(enum) do
        length = 0
        if length == 0 do
          "is 0"
        else
          "something else"
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report when checking if a variable called length is 0 backwards" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(enum) do
        length = 0
        if 0 == length do
          "is 0"
        else
          "something else"
        end
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

  test "it should report when checking if length is 0" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(some_list) do
        if length(some_list) == 0 do
          "empty"
        else
          "not empty"
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "length"
      assert issue.line_no == 3
      assert issue.column == 8
    end)
  end

  test "it should report when checking if length is 0 backwards" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(some_list) do
        if 0 == length(some_list) do
          "empty"
        else
          "not empty"
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "length"
      assert issue.line_no == 3
      assert issue.column == 13
    end)
  end

  test "it should report when checking if Enum.count/1 is 0" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(enum) do
        if Enum.count(some_list) == 0 do
          "empty"
        else
          "not empty"
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "Enum.count"
      assert issue.message =~ "Enum.empty"
      assert issue.line_no == 3
      assert issue.column == 8
    end)
  end

  test "it should report when checking if Enum.count/1 is 0 backwards" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(enum) do
        if 0 == Enum.count(enum) do
          "empty"
        else
          "not empty"
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.message =~ "Enum.empty"
      assert issue.line_no == 3
      assert issue.column == 13
    end)
  end

  test "it should report when checking if Enum.count/2 is 0" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(enum) do
        if Enum.count(some_list, &is_nil/1) == 0 do
          "empty"
        else
          "not empty"
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue -> assert issue.message =~ "Enum.any" end)
  end

  test "it should report when checking if Enum.count/2 is 0 backwards" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(enum) do
        if 0 == Enum.count(enum, &is_nil/1) do
          "empty"
        else
          "not empty"
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue -> assert issue.message =~ "Enum.any" end)
  end

  test "it should report when checking if length is 0 with triple-equals" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(some_list) do
        if length(some_list) === 0 do
          "empty"
        else
          "not empty"
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report when checking if length is unequal to 0" do
    """
    defmodule CredoSampleModule do
      def some_function(some_list) do
        if length(some_list) != 0 do
          "not empty"
        else
          "empty"
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report when checking if length is unequal to 0 /2" do
    """
    defmodule CredoSampleModule do
      def some_function(some_list) do
        if 0 != length(some_list) do
          "not empty"
        else
          "empty"
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report when checking if Enum.count is unequal to 0" do
    """
    defmodule CredoSampleModule do
      def some_function(some_list) do
        if Enum.count(some_list) != 0 do
          "not empty"
        else
          "empty"
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report when checking if Enum.count is unequal to 0 /2" do
    """
    defmodule CredoSampleModule do
      def some_function(some_list) do
        if 0 != Enum.count(some_list) do
          "not empty"
        else
          "empty"
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report when checking if length is not identical to 0" do
    """
    defmodule CredoSampleModule do
      def some_function(some_list) do
        if length(some_list) !== 0 do
          "not empty"
        else
          "empty"
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report when checking if Enum.count is not identical to 0" do
    """
    defmodule CredoSampleModule do
      def some_function(some_list) do
        if Enum.count(some_list) !== 0 do
          "not empty"
        else
          "empty"
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report when checking if length is greater than 0" do
    """
    defmodule CredoSampleModule do
      def some_function(some_list) do
        if length(some_list) > 0 do
          "not empty"
        else
          "empty"
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report when checking if length is greater than 0 /2" do
    """
    defmodule CredoSampleModule do
      def some_function(some_list) do
        if 0 < length(some_list) do
          "not empty"
        else
          "empty"
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report when checking if Enum.count is greater than 0" do
    """
    defmodule CredoSampleModule do
      def some_function(some_list) do
        if Enum.count(some_list) > 0 do
          "not empty"
        else
          "empty"
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report when checking if length is greater than 0 backwards" do
    """
    defmodule CredoSampleModule do
      def some_function(some_list) do
        if 0 < length(some_list) do
          "empty"
        else
          "not empty"
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report when checking if Enum.count is greater than 0 backwards" do
    """
    defmodule CredoSampleModule do
      def some_function(some_list) do
        if 0 < Enum.count(some_list) do
          "empty"
        else
          "not empty"
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report when checking if length is greater or equal to 1" do
    """
    defmodule CredoSampleModule do
      def some_function(some_list) do
        if length(some_list) >= 1 do
          "not empty"
        else
          "empty"
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report when checking if length is greater or equal to 1 backwards" do
    """
    defmodule CredoSampleModule do
      def some_function(some_list) do
        if 1 <= length(some_list) do
          "not empty"
        else
          "empty"
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report when checking if Enum.count is greater or equal to 1" do
    """
    defmodule CredoSampleModule do
      def some_function(some_list) do
        if Enum.count(some_list) >= 1 do
          "not empty"
        else
          "empty"
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report when checking if Enum.count is greater or equal to 1 backwards" do
    """
    defmodule CredoSampleModule do
      def some_function(some_list) do
        if 1 <= Enum.count(some_list) do
          "not empty"
        else
          "empty"
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report when multiple issues (see #1184)" do
    """
    defmodule Test do
      @moduledoc false

      def test do
        enum = []

        if length(enum) != 0 do
          :error
        end

        if length(enum) > 0 do
          :error
        end

        if length(enum) !== 0 do
          :error
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues(fn issues ->
      assert length(issues) == 3
    end)
  end

  for problem_guard <- [
        "length(enum) == 0",
        "length(enum) != 0",
        "length(enum) !== 0",
        "length(enum) > 0",
        "length(enum) >= 0",
        "length(enum) < 0",
        "length(enum) <= 0",
        "0 == length(enum)",
        "0 != length(enum)",
        "0 > length(enum)",
        "0 < length(enum)",
        "length(enum) < 1",
        "length(enum) >= 1",
        "1 <= length(enum)",
        "is_list(enum) and 0 == length(enum)",
        "is_list(enum) or length(enum) == 0",
        "is_list(enum) and not is_map(enum) and length(enum) < 1",
        "is_list(enum) or length(enum) >= 1"
      ] do
    @tag problem_guard: problem_guard
    test "suggests comparing against the empty list in guards (`#{problem_guard}`)", %{
      problem_guard: problem_guard
    } do
      """
      defmodule Test do
        def test(enum) when #{problem_guard} do
          :ok
        end
      end
      """
      |> to_source_file
      |> run_check(@described_check)
      |> assert_issue(fn issue ->
        assert issue.message =~ "empty list"
      end)
    end
  end

  for okay_guard <- [
        "length(enum) > 1",
        "length(enum) <= 1",
        "length(enum) > 2",
        "length(enum) <= 2",
        "length(enum) == 1",
        "length(enum) !== 2"
      ] do
    @tag okay_guard: okay_guard
    test "doesn't suggest comparing against empty list if there is no equivalent empty check (`#{okay_guard}`)",
         %{okay_guard: okay_guard} do
      """
      defmodule Test do
        def test(enum) when #{okay_guard} do
          :ok
        end
      end
      """
      |> to_source_file
      |> run_check(@described_check)
      |> refute_issues()
    end
  end

  test "finds issues in both guards and function body" do
    """
    defmodule Test do
      def test(enum) when length(enum) == 0 do
        length(enum) > 0
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues(fn issues ->
      assert length(issues) == 2
    end)
  end
end
