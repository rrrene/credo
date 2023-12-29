defmodule Credo.Check.Refactor.UtcNowTruncateTest do
  use Credo.Test.Case

  @described_check Credo.Check.Refactor.UtcNowTruncate

  test "should report a violation when applying DateTime.truncate/2 to DateTime.utc_now/0" do
    """
    defmodule M do
      def f do
        DateTime.truncate(DateTime.utc_now(), :second)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "should report a violation when applying DateTime.truncate/2 to DateTime.utc_now/1" do
    """
    defmodule M do
      def f do
        DateTime.truncate(DateTime.utc_now(:second), :second)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "should report a violation when applying DateTime.truncate/2 to DateTime.utc_now/2" do
    """
    defmodule M do
      def f do
        DateTime.truncate(DateTime.utc_now(Calendar.ISO, :second), :second)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "should report a violation when piping result of DateTime.utc_now/0 into DateTime.truncate/2" do
    """
    defmodule M do
      def f do
        DateTime.utc_now() |> DateTime.truncate(:second)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "should report a violation when piping result of DateTime.utc_now/1 into DateTime.truncate/2" do
    """
    defmodule M do
      def f do
        DateTime.utc_now(:second) |> DateTime.truncate(:second)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "should report a violation when piping result of DateTime.utc_now/2 into DateTime.truncate/2" do
    """
    defmodule M do
      def f do
        DateTime.utc_now(Calendar.ISO, :second) |> DateTime.truncate(:second)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "should report a violation when piping argument to DateTime.utc_now/1 and applying DateTime.truncate/2 to that" do
    """
    defmodule M do
      def f do
        DateTime.truncate(:second |> DateTime.utc_now(), :second)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "should report a violation when piping argument to DateTime.utc_now/2 and applying DateTime.truncate/2 to that" do
    """
    defmodule M do
      def f do
        DateTime.truncate(Calendar.ISO |> DateTime.utc_now(:second), :second)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "should report a violation when piping argument to DateTime.utc_now/1 and piping result to DateTime.truncate/2" do
    """
    defmodule M do
      def f do
        :second |> DateTime.utc_now() |> DateTime.truncate(:second)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "should report a violation when piping argument to DateTime.utc_now/2 and piping result to DateTime.truncate/2" do
    """
    defmodule M do
      def f do
        Calendar.ISO |> DateTime.utc_now(:second) |> DateTime.truncate(:second)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "should report a violation when applying NaiveDateTime.truncate/2 to NaiveDateTime.utc_now/0" do
    """
    defmodule M do
      def f do
        NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "should report a violation when applying NaiveDateTime.truncate/2 to NaiveDateTime.utc_now/1" do
    """
    defmodule M do
      def f do
        NaiveDateTime.truncate(NaiveDateTime.utc_now(:second), :second)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "should report a violation when applying NaiveDateTime.truncate/2 to NaiveDateTime.utc_now/2" do
    """
    defmodule M do
      def f do
        NaiveDateTime.truncate(NaiveDateTime.utc_now(Calendar.ISO, :second), :second)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "should report a violation when piping result of NaiveDateTime.utc_now/0 into NaiveDateTime.truncate/2" do
    """
    defmodule M do
      def f do
        NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "should report a violation when piping result of NaiveDateTime.utc_now/1 into NaiveDateTime.truncate/2" do
    """
    defmodule M do
      def f do
        NaiveDateTime.utc_now(:second) |> NaiveDateTime.truncate(:second)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "should report a violation when piping result of NaiveDateTime.utc_now/2 into NaiveDateTime.truncate/2" do
    """
    defmodule M do
      def f do
        NaiveDateTime.utc_now(Calendar.ISO, :second) |> NaiveDateTime.truncate(:second)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "should report a violation when piping argument to NaiveDateTime.utc_now/1 and applying NaiveDateTime.truncate/2 to that" do
    """
    defmodule M do
      def f do
        NaiveDateTime.truncate(:second |> NaiveDateTime.utc_now(), :second)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "should report a violation when piping argument to NaiveDateTime.utc_now/2 and applying NaiveDateTime.truncate/2 to that" do
    """
    defmodule M do
      def f do
        NaiveDateTime.truncate(Calendar.ISO |> NaiveDateTime.utc_now(:second), :second)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "should report a violation when piping argument to NaiveDateTime.utc_now/1 and piping result to NaiveDateTime.truncate/2" do
    """
    defmodule M do
      def f do
        :second |> NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "should report a violation when piping argument to NaiveDateTime.utc_now/2 and piping result to NaiveDateTime.truncate/2" do
    """
    defmodule M do
      def f do
        Calendar.ISO |> NaiveDateTime.utc_now(:second) |> NaiveDateTime.truncate(:second)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "should report a violaton with a correct trigger value for DateTime.truncate/2" do
    """
    defmodule M do
      def f do
        DateTime.truncate(DateTime.utc_now(), :second)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue -> assert issue.trigger == "DateTime.truncate" end)
  end

  test "should report a violaton with a correct trigger value for NaiveDateTime.truncate/2" do
    """
    defmodule M do
      def f do
        NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue -> assert issue.trigger == "NaiveDateTime.truncate" end)
  end
end
