defmodule Credo.Check.Readability.VariableNamesTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.VariableNames

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        some_value = parameter1 + parameter2
        {some_value, _} = parameter1
        [1, some_value] = parameter1
        [some_value | tail] = parameter1
        "e" <> some_value = parameter1
        ^some_value = parameter1
        %{some_value: some_value} = parameter1
        ... = parameter1
        latency_μs = 5
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
        someValue = parameter1 + parameter2
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
        someOtherValue = parameter1 + parameter2
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /3" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        {true, someValue} = parameter1
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
        [1, someValue] = parameter1
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
        [someValue | tail] = parameter1
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /6" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        "e" <> someValue = parameter1
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /7" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        ^someValue = parameter1
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /8" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        %{some_value: someValue} = parameter1
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /9" do
    """
    defmodule CredoSampleModule do
      def some_function(oneParam, twoParam) do
        :ok
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /10" do
    """
    defmodule CredoSampleModule do
      def some_function(param, p2, p3) do
        [someValue + v2 + v3 | {someValue} <- param, v2 <- p2, v3 <- p3]
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /11" do
    """
    defmodule CredoSampleModule do
      def some_function(param) do
        for someValue <- param do
          someValue + 1
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /12" do
    """
    defmodule CredoSampleModule do
      def some_function(param) do
        case param do
          0 -> :ok
          1 -> :ok
          someValue -> :error
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /13" do
    """
    defmodule CredoSampleModule do
      def some_function(_param) do
        try do
          raise "oops"
        catch
          someValue -> :error
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /14" do
    """
    defmodule CredoSampleModule do
      def some_function(param) do
        receive do
          {:get, someJam} -> :ok
          {:put, ^param} -> :ok
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /15" do
    """
    defmodule CredoSampleModule do
      def some_function(timeOut) do
        receive do
          _ -> :ok
        after
          timeOut -> :timeout
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /16" do
    """
    defmodule CredoSampleModule do
      def some_function(param) do
        fn (otherParam) -> param + otherParam end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /17" do
    """
    defmodule CredoSampleModule do
      def some_function(param) do
        with {:ok, v1} <- M.f1(param),
             {:ok, v2} <- M.f2(v1),
             {:ok, someValue} <- M.f3(v2),
             do: M.f0(someValue)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report multiple violations" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        %{some_value: someValue, other_value: otherValue} = parameter1
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues()
  end
end
