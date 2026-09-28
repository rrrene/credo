defmodule Credo.Check.Refactor.ForbiddenNestingTest do
  use Credo.Test.Case

  @described_check Credo.Check.Refactor.ForbiddenNesting

  #
  # default configuration, which forbids a nested `with`
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

  test "it should NOT report a pair that is not forbidden by default" do
    ~S'''
    defmodule CredoSampleModule do
      def price(order, customer) do
        case customer.tier do
          :retail ->
            if order.total > 100 do
              order.total * 0.95
            else
              order.total
            end

          :wholesale ->
            order.total * 0.8
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report anything when configured with no rules" do
    ~S'''
    defmodule CredoSampleModule do
      def fetch(host, deadline) do
        if expired?(deadline) do
          with {:ok, conn} <- connect(host) do
            read(conn)
          end
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, disallow_nested_in: [])
    |> refute_issues()
  end

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

  #
  # scopes, and constructs that are neither scope nor block
  #

  test "it should NOT report a construct at the top of an fn body, however deeply nested" do
    ~S'''
    defmodule CredoSampleModule do
      def prices(orders, discount?) do
        if discount? do
          Enum.map(orders, fn order ->
            if order.total > 100 do
              order.total * 0.95
            else
              order.total
            end
          end)
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, disallow_nested_in: [if: :any])
    |> refute_issues()
  end

  # A `def` and a `defmodule` are both scopes, so each has to be pinned by a case the
  # other cannot account for: here the reported construct sits directly in the module
  # body, with no `def` in between.
  test "it should NOT report a construct in a module body, since defmodule is a scope" do
    ~S'''
    if Code.ensure_loaded?(Jason) do
      defmodule CredoSampleModule do
        if function_exported?(Jason, :encode!, 2) do
          def encode(data), do: Jason.encode!(data, [])
        else
          def encode(data), do: Jason.encode!(data)
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, disallow_nested_in: [if: :any])
    |> refute_issues()
  end

  # And here a function head is the only thing standing between the `with` and the `for`.
  test "it should NOT report a construct in a function generated inside a comprehension" do
    ~S'''
    defmodule CredoSampleModule do
      for host <- @hosts do
        def fetch(unquote(host)) do
          with {:ok, conn} <- connect(unquote(host)) do
            read(conn)
          end
        end

        defp cached(unquote(host)) do
          with {:ok, conn} <- lookup(unquote(host)) do
            read(conn)
          end
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a construct wrapped only in a try, since try is transparent" do
    ~S'''
    defmodule CredoSampleModule do
      def execute(query, dry_run?) do
        try do
          if dry_run? do
            explain(query)
          else
            run(query)
          end
        rescue
          StaleReferenceError -> {:error, :stale_reference}
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, disallow_nested_in: [if: :any])
    |> refute_issues()
  end

  test "it should report a construct in a try that is itself nested, since try is transparent" do
    ~S'''
    defmodule CredoSampleModule do
      def execute(query, dry_run?) do
        case mode() do
          :eager ->
            try do
              if dry_run? do
                explain(query)
              else
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
    |> run_check(@described_check, disallow_nested_in: [if: [:case]])
    |> assert_issue(%{line_no: 6, trigger: "if"})
  end

  # A block can sit in the call-form position rather than in the arguments, which is
  # the one place the traversal has to look at a node's form as well as its args.
  test "it should report a construct in call-form position" do
    ~S'''
    defmodule CredoSampleModule do
      def price(order, customer) do
        case customer.tier do
          :retail ->
            (if order.total > 100 do
               &discount/1
             else
               &full/1
             end).(order)
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, disallow_nested_in: [if: [:case]])
    |> assert_issue(%{line_no: 5, trigger: "if"})
  end

  #
  # other configurations
  #

  test "it should NOT report a nested one-liner when allow_one_liners is true" do
    ~S'''
    defmodule CredoSampleModule do
      def price(order, customer) do
        case customer.tier do
          :retail -> if order.total > 100, do: order.total * 0.95, else: order.total
          :wholesale -> order.total * 0.8
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, disallow_nested_in: [if: [:case]], allow_one_liners: true)
    |> refute_issues()
  end

  test "it should name both constructs in the message and suggest a fix" do
    ~S'''
    defmodule CredoSampleModule do
      def price(order, customer) do
        case customer.tier do
          :retail ->
            if order.total > 100 do
              order.total * 0.95
            else
              order.total
            end
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, disallow_nested_in: [if: [:case]])
    |> assert_issue(fn issue ->
      assert issue.message =~ "`if`"
      assert issue.message =~ "`case`"
      assert issue.message =~ "extract it into a named function"
    end)
  end

  test "it should report an if nested in an if" do
    ~S'''
    defmodule CredoSampleModule do
      def price(order, customer) do
        if customer.active? do
          if order.total > 100 do
            order.total * 0.95
          else
            order.total
          end
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, disallow_nested_in: [if: [:if]])
    |> assert_issue(%{line_no: 4, trigger: "if"})
  end

  test "it should report a nested one-liner by default" do
    ~S'''
    defmodule CredoSampleModule do
      def price(order, customer) do
        case customer.tier do
          :retail -> if order.total > 100, do: order.total * 0.95, else: order.total
          :wholesale -> order.total * 0.8
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, disallow_nested_in: [if: [:case]])
    |> assert_issue(%{line_no: 4, trigger: "if"})
  end

  test "it should report every nested construct sharing a line" do
    ~S'''
    defmodule CredoSampleModule do
      def price(a, b, c) do
        if a, do: (if b, do: 1), else: (if c, do: 2)
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, disallow_nested_in: [if: [:if]])
    |> assert_issues(fn issues ->
      assert Enum.map(issues, &{&1.line_no, &1.trigger}) == [{3, "if"}, {3, "if"}]
    end)
  end

  test "it should accept a map, a bare atom and :any as rule values" do
    source_file =
      ~S'''
      defmodule CredoSampleModule do
        def price(order, customer) do
          case customer.tier do
            :retail ->
              if order.total > 100 do
                order.total * 0.95
              else
                order.total
              end
          end
        end
      end
      '''
      |> to_source_file

    for rules <- [%{if: [:case]}, [if: :case], [if: :any], %{if: :any}] do
      source_file
      |> run_check(@described_check, disallow_nested_in: rules)
      |> assert_issue(%{line_no: 5, trigger: "if"})
    end
  end

  test "it should report a construct nested transitively, naming the innermost match" do
    ~S'''
    defmodule CredoSampleModule do
      def fetch(host, deadline) do
        if expired?(deadline) do
          case mode() do
            :eager ->
              with {:ok, conn} <- connect(host) do
                read(conn)
              end
          end
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, disallow_nested_in: [with: [:if, :case]])
    |> assert_issue(fn issue ->
      assert issue.line_no == 6
      assert issue.trigger == "with"
      assert issue.message =~ "inside `case`"
    end)
  end

  test "it should report a construct nested transitively through an unconfigured block" do
    ~S'''
    defmodule CredoSampleModule do
      def fetch(host, deadline) do
        if expired?(deadline) do
          case mode() do
            :eager ->
              with {:ok, conn} <- connect(host) do
                read(conn)
              end
          end
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, disallow_nested_in: [with: [:if]])
    |> assert_issue(fn issue ->
      assert issue.line_no == 6
      assert issue.trigger == "with"
      assert issue.message =~ "inside `if`"
    end)
  end

  test "it should report several rules at once" do
    ~S'''
    defmodule CredoSampleModule do
      def fetch_all(hosts, deadline) do
        for host <- hosts do
          with {:ok, conn} <- connect(host) do
            read(conn)
          end
        end
      end

      def fetch(host, deadline) do
        unless expired?(deadline) do
          receive do
            :go -> connect(host)
          end
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, disallow_nested_in: [with: [:for], receive: [:unless]])
    |> assert_issues(fn issues ->
      assert Enum.map(issues, &{&1.line_no, &1.trigger}) == [{4, "with"}, {12, "receive"}]
    end)
  end

  #
  # configuration errors
  #

  test "it should raise on constructs that do not open a block" do
    source_file = to_source_file("defmodule CredoSampleModule do\nend\n")

    assert_raise ArgumentError, ~r/`:try` is transparent/, fn ->
      @described_check.run(source_file, disallow_nested_in: [with: [:try]])
    end

    assert_raise ArgumentError, ~r/`:fn` opens a new scope/, fn ->
      @described_check.run(source_file, disallow_nested_in: [fn: [:if]])
    end

    assert_raise ArgumentError, ~r/`:whith` does not open a block/, fn ->
      @described_check.run(source_file, disallow_nested_in: [whith: [:if]])
    end
  end

  test "it should raise on a malformed configuration" do
    source_file = to_source_file("defmodule CredoSampleModule do\nend\n")

    assert_raise ArgumentError, ~r/must be a keyword list or a map/, fn ->
      @described_check.run(source_file, disallow_nested_in: :if)
    end

    assert_raise ArgumentError, ~r/expected a list of constructs or `:any`/, fn ->
      @described_check.run(source_file, disallow_nested_in: [if: "case"])
    end
  end
end
