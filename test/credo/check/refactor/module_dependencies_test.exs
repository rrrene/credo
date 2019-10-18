defmodule Credo.Check.Refactor.ModuleDependenciesTest do
  use Credo.TestHelper

  @described_check Credo.Check.Refactor.ModuleDependencies

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      def some_function() do
        [
          DateTime,
          Kernel,
          GenServer,
          GenEvent,
          File,
          Time,
          IO,
          Logger,
          URI,
          Path
        ]
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
      def some_function() do
        [
          DateTime,
          Kernel,
          GenServer,
          GenEvent,
          File,
          Time,
          IO,
          Logger,
          URI,
          Path,
          String
        ]
      end
    end
    """
    |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should not report a violation on non-umbrella test path" do
    """
    defmodule CredoSampleModule do
      def some_function() do
        [
          DateTime,
          Kernel,
          GenServer,
          GenEvent,
          File,
          Time,
          IO,
          Logger,
          URI,
          Path,
          String
        ]
      end
    end
    """
    |> to_source_file("test/foo/my_test.exs")
    |> refute_issues(@described_check)
  end

  test "it should not report a violation on umbrella test path" do
    """
    defmodule CredoSampleModule do
      def some_function() do
        [
          DateTime,
          Kernel,
          GenServer,
          GenEvent,
          File,
          Time,
          IO,
          Logger,
          URI,
          Path,
          String
        ]
      end
    end
    """
    |> to_source_file("apps/foo/test/foo/my_test.exs")
    |> refute_issues(@described_check)
  end
end
