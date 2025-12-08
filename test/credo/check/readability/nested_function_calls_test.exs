defmodule Credo.Check.Readability.NestedFunctionCallsTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.NestedFunctionCalls

  #
  # cases NOT raising issues
  #

  test "it should NOT report code with nested guard calls" do
    ~S'''
    defmodule CredoSampleModule do
      defguardp nested_guardp(data) when is_atom(hd(hd(data)))
      defguard nested_guard(data) when nested_guardp(data) or is_binary(hd(hd(data)))

      def nested_guard_def(data) when nested_guard_defp(data) or is_binary(hd(hd(data)))
      defp nested_guard_defp(data) when is_atom(hd(hd(data)))
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report code with nested type calls" do
    ~S'''
    defmodule CredoSampleModule do
      @callback callback_name :: Keyword.t(Some.remote(some_arg))
      @macrocallback macrocallback_name :: Keyword.t(Some.remote(some_arg))
      @spec spec_name :: Keyword.t(Some.remote(some_arg))
      @opaque opaque_name :: Keyword.t(Some.remote(some_arg))
      @type type_name :: Keyword.t(Some.remote(some_arg))
      @typep typep_name :: Keyword.t(Some.remote(some_arg))
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report string interpolation" do
    ~S'''
    defmodule CredoSampleModule do
      def some_code do
        "Take 10 #{Enum.take([1, 2, 2, 3, 3], 10)}"
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report char list interpolation" do
    ~s'''
    defmodule CredoSampleModule do
      def some_code do
        'Take 10 #{Enum.take([1, 2, 2, 3, 3], 10)}'
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation for string concatenation" do
    ~S'''
    defmodule Test do
      def test do
        String.captialize("hello" <> "world")
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation for ++" do
    ~S'''
    defmodule CredoSampleModule do
      def some_code do
        Enum.max([1,2,3] ++ [4,5,7])
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation for --" do
    ~S'''
    defmodule CredoSampleModule do
      def some_code do
        Enum.max([1,2,3] -- [4,5,7])
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report Access protocol lookups" do
    ~S'''
    defmodule CredoSampleModule do
      def some_code do
        Enum.take(map[:some_key])
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report nested function calls when the outer function is already in a pipeline" do
    ~S'''
    defmodule CredoSampleModule do
      def some_code do
        [1,2,3,4]
        |> Test.test()
        |> Enum.map(SomeMod.some_fun(argument))
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report two nested functions calls when the inner function call takes no arguments" do
    ~S'''
    defmodule CredoSampleModule do
      def some_code do
        Enum.uniq(some_list())
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report any issues when Kernel.to_string() is called inside a string interpolation" do
    ~S'''
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
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report two nested functions calls when the inner call receives some arguments" do
    ~S'''
    defmodule CredoSampleModule do
      def some_code do
        Enum.shuffle(Enum.uniq([1,2,2,3,3]))
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report three nested functions calls" do
    ~S'''
    defmodule CredoSampleModule do
      def some_code do
        Enum.shuffle(Enum.uniq(Enum.take([1,2,2,3,3], 10)))
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issues()
  end

  test "it should report two nested functions calls when min_pipeline_length is set to one" do
    ~S'''
    defmodule CredoSampleModule do
      def some_code do
        Enum.uniq(some_list())
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check, min_pipeline_length: 1)
    |> assert_issue()
  end

  test "it should NOT report two nested functions calls with arguments when min_pipeline_length is set to three" do
    ~S'''
    defmodule CredoSampleModule do
      def some_code do
        Enum.shuffle(Enum.uniq([1,2,2,3,3]))
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check, min_pipeline_length: 3)
    |> refute_issues()
  end

  test "it should report nested function calls inside a pipeline when the inner function calls could be a pipeline of their own" do
    ~S'''
    defmodule CredoSampleModule do
      def some_code do
        [1,2,3,4]
        |> Test.test()
        |> Enum.map(fn(item) ->
          SomeMod.some_fun(another_fun(item))
        end)
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue(%{line_no: 6, trigger: "SomeMod.some_fun"})
  end
end
