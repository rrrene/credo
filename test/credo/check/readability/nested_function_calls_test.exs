defmodule Credo.Check.Readability.NestedFunctionCallsTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.NestedFunctionCalls

  #
  # cases NOT raising issues
  #

  test "it should NOT report code with no nested function calls" do
    """
    defmodule CredoSampleModule do
      def some_code do
        Enum.shuffle([1,2,3])
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report string interpolation" do
    """
    defmodule CredoSampleModule do
      def some_code do
        "Take 10 #{Enum.take([1, 2, 2, 3, 3], 10)}"
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report char list interpolation" do
    """
    defmodule CredoSampleModule do
      def some_code do
        'Take 10 #{Enum.take([1, 2, 2, 3, 3], 10)}'
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation for string concatenation" do
    """
    defmodule Test do
      def test do
        String.captialize("hello" <> "world")
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation for ++" do
    """
    defmodule CredoSampleModule do
      def some_code do
        Enum.max([1,2,3] ++ [4,5,7])
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation for --" do
    """
    defmodule CredoSampleModule do
      def some_code do
        Enum.max([1,2,3] -- [4,5,7])
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report Access protocol lookups" do
    """
    defmodule CredoSampleModule do
      def some_code do
        Enum.take(map[:some_key])
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report nested function calls when the outer function is already in a pipeline" do
    """
    defmodule CredoSampleModule do
      def some_code do
        [1,2,3,4]
        |> Test.test()
        |> Enum.map(SomeMod.some_fun(argument))
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report two nested functions calls when the inner function call takes no arguments" do
    """
    defmodule CredoSampleModule do
      def some_code do
        Enum.uniq(some_list())
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report any issues when Kernel.to_string() is called inside a string interpolation" do
    ~S"""
    defmodule FeatureFlag.Adapters.Test do
      def get(flag, context, fallback) do
        args = {flag, context, fallback}
        case :ets.lookup(@table, flag) do
          [] ->
            raise "No stubs found for #{inspect(args)}"

          stubs ->
            attempt_stubs(args, Enum.reverse(stubs))
        end
      end

      defp attempt_stubs(args, []) do
        raise "No stub found for args: #{inspect(args)}"
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report two nested functions calls when the inner call receives some arguments" do
    """
    defmodule CredoSampleModule do
      def some_code do
        Enum.shuffle(Enum.uniq([1,2,2,3,3]))
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report three nested functions calls" do
    """
    defmodule CredoSampleModule do
      def some_code do
        Enum.shuffle(Enum.uniq(Enum.take([1,2,2,3,3], 10)))
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issues()
  end

  test "it should report two nested functions calls when min_pipeline_length is set to one" do
    """
    defmodule CredoSampleModule do
      def some_code do
        Enum.uniq(some_list())
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check, min_pipeline_length: 1)
    |> assert_issue()
  end

  test "it should NOT report two nested functions calls with arguments when min_pipeline_length is set to three" do
    """
    defmodule CredoSampleModule do
      def some_code do
        Enum.shuffle(Enum.uniq([1,2,2,3,3]))
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check, min_pipeline_length: 3)
    |> refute_issues()
  end

  test "it should report nested function calls inside a pipeline when the inner function calls could be a pipeline of their own" do
    """
    defmodule CredoSampleModule do
      def some_code do
        [1,2,3,4]
        |> Test.test()
        |> Enum.map(fn(item) ->
          SomeMod.some_fun(another_fun(item))
        end)
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end
end
