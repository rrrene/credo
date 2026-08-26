defmodule Credo.Check.Refactor.NestedWithTest do
  use Credo.Test.Case

  @described_check Credo.Check.Refactor.NestedWith

  #
  # cases NOT raising issues
  #

  test "it should NOT report a with at the top of a function body" do
    ~S'''
    defmodule CredoSampleModule do
      def fetch(host) do
        with {:ok, conn} <- connect(host),
             request = build_request(conn),
             {:ok, response} <- send(conn, request) do
          {:ok, response}
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a with at the top of a private function or in keyword form" do
    ~S'''
    defmodule CredoSampleModule do
      defp read(conn) do
        with {:ok, data} <- recv(conn) do
          data
        end
      end

      defp normalize(args) do
        args = with nil <- args, do: []

        args
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a with at the top of an fn body, however deeply nested" do
    ~S'''
    defmodule CredoSampleModule do
      def fetch_all(hosts, deadline) do
        if expired?(deadline) do
          []
        else
          Enum.map(hosts, fn host ->
            with {:ok, conn} <- connect(host) do
              read(conn)
            end
          end)
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a with wrapped in a try" do
    ~S'''
    defmodule CredoSampleModule do
      def execute(query) do
        try do
          with {:ok, query} <- validate(query),
               {:ok, result} <- run(query) do
            {:ok, result}
          end
        rescue
          StaleReferenceError -> {:error, :stale_reference}
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report calls to functions called \"with\"" do
    ~S'''
    defmodule CredoSampleModule do
      def fetch(parameter1, parameter2) do
        if parameter1 do
          with(parameter1, parameter2)
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a module wrapped in a conditional compilation if" do
    ~S'''
    if Code.ensure_loaded?(Jason) do
      defmodule CredoSampleModule do
        def encode(data) do
          with {:ok, json} <- Jason.encode(data) do
            json
          end
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a with nested in another with" do
    ~S'''
    defmodule CredoSampleModule do
      def fetch(host) do
        with {:ok, conn} <- connect(host) do
          request = build_request(conn)

          with {:ok, response} <- send(conn, request) do
            {:ok, response}
          end
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(%{line_no: 6, trigger: "with"})
  end

  test "it should report a with nested in an if" do
    ~S'''
    defmodule CredoSampleModule do
      def fetch(host, deadline) do
        if expired?(deadline) do
          {:error, :timeout}
        else
          with {:ok, conn} <- connect(host) do
            read(conn)
          end
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(%{line_no: 6, trigger: "with"})
  end

  test "it should report a with nested in a case" do
    ~S'''
    defmodule CredoSampleModule do
      def fetch(host, mode) do
        case mode do
          :eager ->
            with {:ok, conn} <- connect(host) do
              read(conn)
            end

          :lazy ->
            {:ok, host}
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(%{line_no: 5, trigger: "with"})
  end

  test "it should report a with nested in a comprehension" do
    ~S'''
    defmodule CredoSampleModule do
      def fetch_all(hosts) do
        for host <- hosts do
          with {:ok, conn} <- connect(host) do
            read(conn)
          end
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(%{line_no: 4, trigger: "with"})
  end

  test "it should report a with in a try that is itself nested, since try is transparent" do
    ~S'''
    defmodule CredoSampleModule do
      def execute(query, deadline) do
        if expired?(deadline) do
          {:error, :timeout}
        else
          try do
            with {:ok, query} <- validate(query) do
              run(query)
            end
          rescue
            StaleReferenceError -> {:error, :stale_reference}
          end
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(%{line_no: 7, trigger: "with"})
  end

  test "it should report each nested with once" do
    ~S'''
    defmodule CredoSampleModule do
      def fetch(host, deadline) do
        if expired?(deadline) do
          with {:ok, conn} <- connect(host) do
            read(conn)
          end
        else
          with {:ok, conn} <- reconnect(host) do
            read(conn)
          end
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues(fn issues ->
      assert length(issues) == 2
      assert Enum.map(issues, & &1.line_no) == [4, 8]
      assert Enum.all?(issues, &(&1.trigger == "with"))
    end)
  end
end
