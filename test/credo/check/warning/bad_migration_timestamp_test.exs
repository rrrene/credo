defmodule Credo.Check.Warning.BadMigrationTimestampTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.BadMigrationTimestamp

  #
  # cases NOT raising issues
  #

  test "it should NOT report files that start with timestamp in past" do
    """
    defmodule Credo.Check.Warning.BadMigrationTimestampTest do
      use Ecto.Migration
      def change do
        fake_migration
      end
    end
    """
    |> to_source_file("priv/repo/migrations/20210331180839_test_case.exs")
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report non migration files" do
    """
    defmodule Credo.Check.Warning.BadMigrationTimestampTest do
      def test do
        "test"
      end
    end
    """
    |> to_source_file("random_path/some_file.ex")
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report files that have too long a timestamp" do
    """
    defmodule Credo.Check.Warning.BadMigrationTimestampTest do
      use Ecto.Migration
      def change do
        fake_migration
      end
    end
    """
    |> to_source_file("priv/repo/migrations/202103311808399_test_case.exs")
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report files that have a timestamp in the future" do
    """
    defmodule Credo.Check.Warning.BadMigrationTimestampTest do
      use Ecto.Migration
      def change do
        fake_migration
      end
    end
    """
    |> to_source_file("priv/repo/migrations/22210331180839_test_case.exs")
    |> run_check(@described_check)
    |> assert_issue()
  end
end
