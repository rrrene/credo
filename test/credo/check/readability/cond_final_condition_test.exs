defmodule Credo.Check.Readability.CondFinalConditionTest do
  use Credo.Test.Case

  alias Credo.Check.Readability.CondFinalCondition

  test "it should NOT report conds with a last condition of true" do
    """
    defmodule CredoSampleModule do
      def cond_true(a) do
        cond do
          a + 2 == 5 ->
            "Nope"

          a + 3 == 5 ->
            "Uh, uh"

          true ->
            "OK"
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(CondFinalCondition)
    |> refute_issues()
  end

  test "it should NOT report conds with a last condition that uses a variable" do
    """
    defmodule CredoSampleModule do
      def cond_true(a) do
        cond do
          a + 2 == 5 ->
            "Nope"

          a + 3 == 5 ->
            "Uh, uh"
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(CondFinalCondition)
    |> refute_issues()
  end

  test "it should report conds that with a last condition that is some other literal" do
    """
    defmodule CredoSampleModule do
      def cond_true(a) do
        cond do
          a + 2 == 5 ->
            "Nope"

          a + 3 == 5 ->
            "Uh, uh"

          :else ->
            "OK"
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(CondFinalCondition)
    |> assert_issue()
  end

  test "it should report conds that with a last condition that is binary literal" do
    """
    defmodule CredoSampleModule do
      def cond_true(a) do
        cond do
          a + 2 == 5 ->
            "Nope"

          a + 3 == 5 ->
            "Uh, uh"

          "else" ->
            "OK"
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(CondFinalCondition)
    |> assert_issue()
  end

  test "it should report conds that with a last condition that is integer literal" do
    """
    defmodule CredoSampleModule do
      def cond_true(a) do
        cond do
          a + 2 == 5 ->
            "Nope"

          a + 3 == 5 ->
            "Uh, uh"

          123 ->
            "OK"
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(CondFinalCondition)
    |> assert_issue()
  end

  test "it should report conds that with a last condition that is list literal" do
    """
    defmodule CredoSampleModule do
      def cond_true(a) do
        cond do
          a + 2 == 5 ->
            "Nope"

          a + 3 == 5 ->
            "Uh, uh"

          [:else] ->
            "OK"
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(CondFinalCondition)
    |> assert_issue()
  end

  test "it should report conds that with a last condition that is tuple literal" do
    """
    defmodule CredoSampleModule do
      def cond_true(a) do
        cond do
          a + 2 == 5 ->
            "Nope"

          a + 3 == 5 ->
            "Uh, uh"

          {:else} ->
            "OK"
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(CondFinalCondition)
    |> assert_issue()
  end

  test "it should report conds that with a last condition that is map literal" do
    """
    defmodule CredoSampleModule do
      def cond_true(a) do
        cond do
          a + 2 == 5 ->
            "Nope"

          a + 3 == 5 ->
            "Uh, uh"

          %{} ->
            "OK"
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(CondFinalCondition)
    |> assert_issue()
  end

  test "it should report conds that with a last condition that differ from config" do
    """
    defmodule CredoSampleModule do
      def cond_true(a) do
        cond do
          a + 2 == 5 ->
            "Nope"

          a + 3 == 5 ->
            "Uh, uh"

          true ->
            "OK"
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(CondFinalCondition, final_condition_value: :else)
    |> assert_issue()
  end

  test "it should NOT report conds that with a last condition that match config" do
    """
    defmodule CredoSampleModule do
      def cond_true(a) do
        cond do
          a + 2 == 5 ->
            "Nope"

          a + 3 == 5 ->
            "Uh, uh"

          :else ->
            "OK"
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(CondFinalCondition, final_condition_value: :else)
    |> refute_issues()
  end
end
