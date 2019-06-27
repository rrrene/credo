defmodule Credo.Check.Readability.NilElseTest do
  use Credo.TestHelper

  @described_check Credo.Check.Readability.NilElse

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun(x) do
        if x > 10 do
          x
        else
          :foo
        end
      end
    end
    """
    |> to_source_file
    |> refute_issues(@described_check)
  end

  # #
  # # cases raising issues
  # #

  test "it should report a violation" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun(x) do
        if x > 10 do
          x
        else
          nil
        end
      end
    end
    """
    |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation for multiple violations" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun(x) do
        y =
          if x > 10 do
            x
          else
            nil
          end

        if y do
          y * 2
        else
          nil
        end
     end
    end
    """
    |> to_source_file
    |> assert_issues(@described_check)
  end
end
