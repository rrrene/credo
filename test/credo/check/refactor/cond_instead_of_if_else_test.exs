defmodule Credo.Check.Refactor.CondInsteadOfIfElseTest do
  use Credo.Test.Case

  @described_check Credo.Check.Refactor.CondInsteadOfIfElse

  #
  # cases NOT raising issues
  #

  test "it should NOT report if without else" do
    """
    defmodule CredoSampleModule do
      def some_fun do
        if allowed? do
          :ok
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report inline if without else" do
    """
    defmodule CredoSampleModule do
      def some_fun do
        if allowed?, do: :ok
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report cond statement" do
    """
    defmodule CredoSampleModule do
      def some_fun do
        cond do
          x < y -> -1
          x == y -> 0
          true -> 1
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report multiple if statements without else" do
    """
    defmodule CredoSampleModule do
      def some_fun do
        if condition1 do
          action1()
        end

        if condition2 do
          action2()
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report module attribute named @if" do
    """
    defmodule CredoSampleModule do
      @if true

      def some_fun do
        @if
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

  test "it should report basic if/else block" do
    """
    defmodule CredoSampleModule do
      def some_fun do
        if allowed? do
          :ok
        else
          :error
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(%{trigger: "if"})
  end

  test "it should report inline if/else" do
    """
    defmodule CredoSampleModule do
      def some_fun do
        if allowed?, do: :ok, else: :error

        cond do
          allowed? -> :ok
          true -> :error
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(%{trigger: "if"})
  end

  test "it should report if/else with complex condition" do
    """
    defmodule CredoSampleModule do
      def some_fun(x, y, z) do
        if x > y and y < z or z == 0 do
          :complex
        else
          :simple
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(%{trigger: "if"})
  end

  test "it should report nested if/else within function" do
    """
    defmodule CredoSampleModule do
      def some_fun do
        result = if condition do
          :yes
        else
          :no
        end
        result
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(%{trigger: "if"})
  end

  test "it should report multiple if/else blocks" do
    """
    defmodule CredoSampleModule do
      def some_fun do
        if condition1 do
          :a
        else
          :b
        end

        if condition2 do
          :c
        else
          :d
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues()
  end

  test "it should report correct line number" do
    """
    defmodule CredoSampleModule do
      def some_fun do
        if allowed? do
          :ok
        else
          :error
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(%{line_no: 3})
  end

  #
  # cases with allow_one_liners: true
  #

  test "it should NOT report inline if/else when allow_one_liners is true" do
    """
    defmodule CredoSampleModule do
      def some_fun do
        if allowed?, do: :ok, else: :error
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check, allow_one_liners: true)
    |> refute_issues()
  end

  test "it should still report block if/else when allow_one_liners is true" do
    """
    defmodule CredoSampleModule do
      def some_fun do
        if allowed? do
          :ok
        else
          :error
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check, allow_one_liners: true)
    |> assert_issue(%{trigger: "if"})
  end

  test "it should report inline if/else when allow_one_liners is false (default)" do
    """
    defmodule CredoSampleModule do
      def some_fun do
        if allowed?, do: :ok, else: :error
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check, allow_one_liners: false)
    |> assert_issue(%{trigger: "if"})
  end

  test "it should report only block if/else when allow_one_liners is true with mixed code" do
    """
    defmodule CredoSampleModule do
      def some_fun do
        x = if inline?, do: :a, else: :b

        if block? do
          :c
        else
          :d
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check, allow_one_liners: true)
    |> assert_issue(%{line_no: 5})
  end
end
