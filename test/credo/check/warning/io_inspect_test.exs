defmodule Credo.Check.Warning.IoInspectTest do
  use Credo.TestHelper

  @described_check Credo.Check.Warning.IoInspect

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        parameter1 + parameter2
      end
    end
    """
    |> to_source_file
    |> refute_issues(@described_check)
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        IO.inspect parameter1 + parameter2
      end
    end
    """
    |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation /2" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        parameter1 + parameter2
        |> IO.inspect
      end
    end
    """
    |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation /3" do
    """
    defmodule CredoSampleModule do
      def some_function(a, b, c) do
        map([a,b,c], &IO.inspect(&1))
      end
    end
    """
    |> to_source_file
    |> assert_issue(@described_check)
  end

  test "should not report if filename excluded" do
    """
    defmodule CredoSampleModule do
      def some_function(a, b, c) do
        map([a,b,c], &IO.inspect(&1))
      end
    end
    """
    |> to_source_file("its_a_match.exs")
    |> refute_issues(@described_check, excluded: [~r/its_a_match\.exs$/])
  end

  test "should report if filename is not excluded" do
    """
    defmodule CredoSampleModule do
      def some_function(a, b, c) do
        map([a,b,c], &IO.inspect(&1))
      end
    end
    """
    |> to_source_file("its_a_not_a_match.exs")
    |> assert_issue(@described_check, excluded: [~r/its_a_match\.exs$/])
  end
end
