defmodule Credo.Check.Readability.CondFinalConditionTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.CondFinalCondition

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
    |> run_check(@described_check)
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
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report conds with a last condition that match the config" do
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
    |> run_check(@described_check, value: :else)
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
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report conds with a last condition that is a binary literal" do
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
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report conds with a last condition that is an integer literal" do
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
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report conds with a last condition that is a list literal" do
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
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report conds with a last condition that is a tuple literal" do
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
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report conds with a last condition that is a map literal" do
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
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report conds with a last condition that differ from the config" do
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
    |> run_check(@described_check, value: :else)
    |> assert_issue()
  end
end
