defmodule Credo.Check.Readability.SpecParameterNamesTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.SpecParameterNames

  #
  # cases NOT raising issues
  #

  test "it should NOT report a spec with all named parameters" do
    ~S'''
    defmodule CredoSampleModule do
      @spec create_user(attrs :: map(), email :: String.t()) :: {:ok, term()}
      def create_user(attrs, email), do: {:ok, {attrs, email}}
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a zero-arity spec" do
    ~S'''
    defmodule CredoSampleModule do
      @spec config() :: keyword()
      def config, do: []
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a guard-style spec with named parameters" do
    ~S'''
    defmodule CredoSampleModule do
      @spec foo(value :: x, opts :: keyword()) :: x when x: term()
      def foo(value, _opts), do: value
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a @callback with named parameters" do
    ~S'''
    defmodule CredoSampleBehaviour do
      @callback handle_event(event :: String.t(), params :: map()) :: :ok
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report named parameters using remote types" do
    ~S'''
    defmodule CredoSampleModule do
      @spec list(scope :: Scope.t(), opts :: Keyword.t()) :: [term()]
      def list(_scope, _opts), do: []
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a spec with a single unnamed parameter" do
    ~S'''
    defmodule CredoSampleModule do
      @spec greet(String.t()) :: String.t()
      def greet(name), do: "hello " <> name
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report each unnamed parameter in a spec" do
    ~S'''
    defmodule CredoSampleModule do
      @spec create_user(map(), String.t()) :: {:ok, term()}
      def create_user(attrs, email), do: {:ok, {attrs, email}}
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues(fn issues -> assert length(issues) == 2 end)
  end

  test "it should report only the unnamed parameters in a mixed spec" do
    ~S'''
    defmodule CredoSampleModule do
      @spec create_user(attrs :: map(), String.t()) :: {:ok, term()}
      def create_user(attrs, email), do: {:ok, {attrs, email}}
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report unnamed parameters in a guard-style spec" do
    ~S'''
    defmodule CredoSampleModule do
      @spec foo(x, keyword()) :: x when x: term()
      def foo(value, _opts), do: value
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues(fn issues -> assert length(issues) == 2 end)
  end

  test "it should report unnamed parameters in a @callback" do
    ~S'''
    defmodule CredoSampleBehaviour do
      @callback handle_event(String.t(), map()) :: :ok
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues(fn issues -> assert length(issues) == 2 end)
  end

  test "it should report across multiple specs in one module" do
    ~S'''
    defmodule CredoSampleModule do
      @spec one(integer()) :: integer()
      def one(a), do: a

      @spec two(integer(), integer()) :: integer()
      def two(a, b), do: a + b
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues(fn issues -> assert length(issues) == 3 end)
  end
end
