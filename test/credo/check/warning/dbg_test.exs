defmodule Credo.Check.Warning.DbgTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.Dbg

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

  test "it should NOT report when defining dbg fn" do
    """
    defmodule CredoSampleModule do
      def dbg(my_param1, my_param2, myparam3) do
        my_param
      end

      def some_fun(param1, param2, param3) do
        dbg(param1 + param2, param3 * 4, false)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues
  end

  test "it should NOT report when assigning and using dbg var" do
    """
    defmodule CredoSampleModule do
      def some_fun(param1, param2) do
        dbg = param1 + param2
        param3 = dbg + 4
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues
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
        parameter1 + parameter2 |> dbg()
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
      def some_function(a, b, c) do
        map([a,b,c], &dbg(&1))
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
        Kernel.dbg(parameter1 + parameter2)
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
      def dbg(my_param, my_param2, my_param3) do
        my_param
      end

      def some_fun(param1, param2) do
        Kernel.dbg(param1)
        dbg(param1, AnotherModule.another_fun(param2), param1 + param2)
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
      def some_fun(params) do
        dbg = dbg(params)
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
      def some_fun(params) do
        dbg()
        params
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
      def some_fun(params) do
        dbg = params + 1
        dbg
        dbg()
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
      defmodule CredoSampleModule do
        def some_function(parameter1, parameter2) do
          Elixir.Kernel.dbg(parameter1 + parameter2)
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end
end
