defmodule Credo.Check.Warning.ExpensiveEmptyEnumCheckTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.ExpensiveEmptyEnumCheck

  #
  # cases NOT raising issues
  #

  test "it should NOT report when when using length with non zero" do
    """
    defmodule CredoSampleModule do
      def some_function(some_list) do
        if length(some_list) == 2 do
          "has 2"
        else
          "something else"
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report when when using length with non zero backwards" do
    """
    defmodule CredoSampleModule do
      def some_function(some_list) do
        if 2 == length(some_list) do
          "has 2"
        else
          "something else"
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report when checking if Enum.count is non 0" do
    """
    defmodule CredoSampleModule do
      def some_function(enum) do
        if Enum.count(enum) == 3 do
          "has 3"
        else
          "something else"
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report when checking if Enum.count is non 0 backwards" do
    """
    defmodule CredoSampleModule do
      def some_function(enum) do
        if 3 == Enum.count(enum) do
          "has 3"
        else
          "something else"
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report when checking if a variable called length is 0" do
    """
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
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report when checking if a variable called length is 0 backwards" do
    """
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
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report when checking if length is 0" do
    """
    defmodule CredoSampleModule do
      def some_function(some_list) do
        if length(some_list) == 0 do
          "empty"
        else
          "not empty"
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "length"
    end)
  end

  test "it should report when checking if length is 0 backwards" do
    """
    defmodule CredoSampleModule do
      def some_function(some_list) do
        if 0 == length(some_list) do
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

  test "it should report when checking if Enum.count/1 is 0" do
    """
    defmodule CredoSampleModule do
      def some_function(enum) do
        if Enum.count(some_list) == 0 do
          "empty"
        else
          "not empty"
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "Enum.count"
      assert issue.message =~ "Enum.empty"
    end)
  end

  test "it should report when checking if Enum.count/1 is 0 backwards" do
    """
    defmodule CredoSampleModule do
      def some_function(enum) do
        if 0 == Enum.count(enum) do
          "empty"
        else
          "not empty"
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue -> assert issue.message =~ "Enum.empty" end)
  end

  test "it should report when checking if Enum.count/2 is 0" do
    """
    defmodule CredoSampleModule do
      def some_function(enum) do
        if Enum.count(some_list, &is_nil/1) == 0 do
          "empty"
        else
          "not empty"
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue -> assert issue.message =~ "Enum.any" end)
  end

  test "it should report when checking if Enum.count/2 is 0 backwards" do
    """
    defmodule CredoSampleModule do
      def some_function(enum) do
        if 0 == Enum.count(enum, &is_nil/1) do
          "empty"
        else
          "not empty"
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue -> assert issue.message =~ "Enum.any" end)
  end

  test "it should report when checking if length is 0 with triple-equals" do
    """
    defmodule CredoSampleModule do
      def some_function(some_list) do
        if length(some_list) === 0 do
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
end
