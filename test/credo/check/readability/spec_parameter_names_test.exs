defmodule Credo.Check.Readability.SpecParameterNamesTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.SpecParameterNames

  #
  # cases NOT raising issues
  #

  test "it should NOT report a spec with all named parameters" do
    ~S'''
    defmodule CredoSampleModule do
      @spec create_user(attrs :: map(), email :: String.t(), source_file :: [SourceFile.t()]) :: {:ok, term()}
      def create_user(attrs, email, source_file), do: {:ok, {attrs, email}}
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

  test "it should report a spec with unnamed parameters" do
    ~S'''
    defmodule CredoSampleModule do
      @spec create_user(attrs :: map(), email :: String.t(), [SourceFile.t()]) :: {:ok, term()}
      def create_user(attrs, email, source_file), do: {:ok, {attrs, email}}
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(%{trigger: "SourceFile.t"})
  end

  test "it should report a spec with unnamed parameters /2" do
    ~S'''
    defmodule CredoSampleModule do
      @spec create_user(parent, String.t(), (binary() -> any())) :: parent
      def create_user(attrs, email, source_file), do: {:ok, {attrs, email}}
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues(3)
  end

  test "it should report a spec with unnamed parameters /3" do
    ~S'''
    defmodule CredoSampleModule do
      @spec create_user(parent, String.t(), list, (-> any())) :: parent
      def create_user(attrs, email, source_file), do: {:ok, {attrs, email}}
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues(3)
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
    |> assert_issues(2)
  end

  test "it should report a spec with unnamed parameters /4" do
    ~S'''
    defmodule CredoSampleModule do
      @spec fill_in(parent, Query.t(), with: String.t()) :: parent
      def create_user(attrs, email, source_file), do: {:ok, {attrs, email}}
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues(3)
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
    |> assert_issues(2)
  end

  test "it should report unnamed parameters in a @callback" do
    ~S'''
    defmodule CredoSampleBehaviour do
      @callback handle_event(String.t(), map()) :: :ok
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues(2)
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
    |> assert_issues(3)
  end

  test "it should report across multiple specs for different reasons" do
    ~S'''
    defmodule CredoSampleModule do
      @callback assoc_query(t, Ecto.Query.t() | nil, values :: [term]) :: Ecto.Query.t()
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues(2)
    |> assert_issues_match([%{trigger: "t"}, %{trigger: "Ecto.Query.t"}])
  end

  test "it should report across multiple specs for different reasons /2" do
    ~S'''
    defmodule CredoSampleModule do
      @callback server_info(Plug.Conn.scheme()) ::
        {:ok, {:inet.ip_address(), :inet.port_number()} | :inet.returned_non_ip_address()}
        | {:error, term()}
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(%{trigger: "Plug.Conn.scheme"})
  end

  test "it should report across multiple specs for different reasons /3" do
    ~S'''
    defmodule CredoSampleModule do
      @callback build(t, owner :: Ecto.Schema.t(), %{atom => term} | [Keyword.t()]) :: Ecto.Schema.t()
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues(2)
    |> assert_issues_match([%{trigger: "t"}, %{trigger: "Keyword.t"}])
  end

  test "it should report across multiple specs for different reasons /4" do
    ~S'''
    defmodule CredoSampleModule do
      @callback get_and_update(data, key, (value | nil -> {current_value, new_value :: value} | :pop)) ::
                  {current_value, new_data :: data}
                when current_value: value, data: container
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues(3)
  end

  test "it should report across multiple specs for different reasons /5" do
    ~S'''
    defmodule CredoSampleModule do
      @spec shift(DateTime.t(), list({atom(), term})) :: DateTime.t() | {:error, term}
      def shift(%DateTime{} = datetime, shifts) when is_list(shifts) do
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues(3)
  end
end
