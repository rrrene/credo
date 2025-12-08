defmodule Credo.Check.Refactor.ModuleDependenciesTest do
  use Credo.Test.Case

  @described_check Credo.Check.Refactor.ModuleDependencies

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    ~S'''
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
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when using param :excluded_paths" do
    ~S'''
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
    '''
    |> to_source_file("test/foo/my_test.exs")
    |> run_check(@described_check, excluded_paths: [~r"test/foo"])
    |> refute_issues()
  end

  test "it should NOT report a violation on umbrella test path" do
    ~S'''
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
    '''
    |> to_source_file("apps/foo/test/foo/my_test.exs")
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when using param :max_deps" do
    ~S'''
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
    '''
    |> to_source_file
    |> run_check(@described_check, max_deps: 20)
    |> refute_issues()
  end

  test "it should NOT report a violation when using param :excluded_namespaces" do
    ~S'''
    defmodule CredoSample.Excluded.Module do
      def some_function() do
        [
          Foo.Bar.DateTime,
          Foo.Bar.Kernel,
          Foo.Bar.GenServer,
          Foo.Bar.GenEvent,
          Foo.Bar.File,
          Foo.Bar.Time,
          Foo.Bar.IO,
          Foo.Bar.Logger,
          URI,
          Path,
          String
        ]
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, excluded_namespaces: ["CredoSample.Excluded"])
    |> refute_issues()
  end

  test "it should NOT report a violation when using param :dependency_namespaces" do
    ~S'''
    defmodule CredoSample.Excluded.Module do
      def some_function() do
        [
          Foo.Bar.DateTime,
          Foo.Bar.Kernel,
          Foo.Bar.GenServer,
          Foo.Bar.GenEvent,
          Foo.Bar.File,
          Foo.Bar.Time,
          Foo.Bar.IO,
          Foo.Bar.Logger,
          URI,
          Path,
          String
        ]
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, dependency_namespaces: ["Foo.Bar"])
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    ~S'''
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
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(%{line_no: 1, trigger: "CredoSampleModule"})
  end
end
