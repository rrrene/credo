defmodule Credo.Check.Warning.KernelDbgTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.KernelDbg

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
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report when dbg is variable" do
    """
    defmodule CredoSampleModule do
      def some_function() do
        dbg = "hello"
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report when dbg is variable /2" do
    """
    defmodule CredoSampleModule do
      def some_function(dbg) do
        dbg
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

  test "it should report a violation" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        dbg parameter1 + parameter2
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /2" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        parameter1 + parameter2
        |> dbg
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()

    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        parameter1 + parameter2
        |> dbg()
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /4" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        Elixir.Kernel.dbg parameter1 + parameter2
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /5" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        Kernel.dbg parameter1 + parameter2
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end
end
