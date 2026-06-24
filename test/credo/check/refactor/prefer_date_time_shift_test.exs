defmodule Credo.Check.Refactor.PreferDateTimeShiftTest do
  use Credo.Test.Case

  @described_check Credo.Check.Refactor.PreferDateTimeShift

  #
  # cases NOT raising issues
  #

  test "does not flag DateTime.shift" do
    ~S'''
    defmodule Sample do
      def f(dt), do: DateTime.shift(dt, hour: 1)
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "does not flag NaiveDateTime.shift" do
    ~S'''
    defmodule Sample do
      def f(dt), do: NaiveDateTime.shift(dt, day: 7)
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "does not flag Duration.add" do
    ~S'''
    defmodule Sample do
      def f(d1, d2), do: Duration.add(d1, d2)
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "does not flag a local add/3 function" do
    ~S'''
    defmodule Sample do
      def add(a, b, c), do: a + b + c
      def f, do: add(1, 2, 3)
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "flags 3-arg call form" do
    ~S'''
    defmodule Sample do
      def f(dt), do: DateTime.add(dt, 1, :hour)
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue(fn issue -> assert issue.trigger == "DateTime.add" end)
  end

  test "flags 2-arg call form (default :second)" do
    ~S'''
    defmodule Sample do
      def f(dt), do: DateTime.add(dt, 3600)
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "flags pipe form" do
    ~S'''
    defmodule Sample do
      def f(dt), do: dt |> DateTime.add(1, :day)
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "flags every occurrence" do
    ~S'''
    defmodule Sample do
      def f(dt) do
        a = DateTime.add(dt, 1, :hour)
        b = DateTime.add(a, 60, :minute)
        DateTime.add(b, 1, :day)
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issues(fn issues -> assert length(issues) == 3 end)
  end

  test "flags NaiveDateTime.add" do
    ~S'''
    defmodule Sample do
      def f(dt), do: NaiveDateTime.add(dt, 7, :day)
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue(fn issue -> assert issue.trigger == "NaiveDateTime.add" end)
  end

  test "flags Date.add" do
    ~S'''
    defmodule Sample do
      def f(d), do: Date.add(d, 1)
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue(fn issue -> assert issue.trigger == "Date.add" end)
  end

  test "flags Time.add" do
    ~S'''
    defmodule Sample do
      def f(t), do: Time.add(t, 30, :minute)
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue(fn issue -> assert issue.trigger == "Time.add" end)
  end
end
