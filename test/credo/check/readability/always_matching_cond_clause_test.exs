defmodule Credo.Check.Readability.AlwaysMatchingCondClauseTest do
  use Credo.TestHelper

  @described_check Credo.Check.Readability.AlwaysMatchingCondClause

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun(x) do
        cond do
          x > 5 -> "yay"
          x < 5 -> "nay"
          true -> "meh"
        end

        cond do
          x > 5 -> "yay"
          x < 5 -> "nay"
          :else -> "meh"
        end
      end
    end
    """
    |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should NOT report a violation when additional values are configured" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun(x) do
        cond do
          x > 5 -> "yay"
          x < 5 -> "nay"
          :foo -> "meh"
        end
      end
    end
    """
    |> to_source_file
    |> refute_issues(@described_check, allowed_values: [:foo])
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun(x) do
        cond do
          x > 5 -> "yay"
          x < 5 -> "nay"
          :foo -> "meh"
        end
      end
    end
    """
    |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation if the default allowed values are overridden" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun(x) do
        cond do
          x > 5 -> "yay"
          x < 5 -> "nay"
          :else -> "meh"
        end
      end
    end
    """
    |> to_source_file
    |> assert_issue(@described_check, allowed_values: [:foo])
  end

  test "it should report a violation for multiple violations" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun do
        cond do
          x > 5 -> "yay"
          x < 5 -> "nay"
          :foo -> "meh"
        end

        cond do
          x > 5 -> "yay"
          x < 5 -> "nay"
          :other -> "meh"
        end
      end
    end
    """
    |> to_source_file
    |> assert_issues(@described_check)
  end
end
