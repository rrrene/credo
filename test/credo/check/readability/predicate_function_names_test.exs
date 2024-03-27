defmodule Credo.Check.Readability.PredicateFunctionNamesTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.PredicateFunctionNames

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    def valid? do
    end
    defp has_attachment? do
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report expected code with arity on function" do
    """
    def valid?(a) do
    end
    defp has_attachment?(a) do
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation with defmacro" do
    """
    defmacro is_user(cookie) do
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation with quote" do
    ~S'''
    defmodule ElixirScript.FFI do
      defmacro __using__(opts) do
        quote do
          import ElixirScript.FFI
          Module.register_attribute __MODULE__, :__foreign_info__, persist: true
          @__foreign_info__ %{
            path: Macro.underscore(__MODULE__),
            name: unquote(Keyword.get(opts, :name, nil)),
            global: unquote(Keyword.get(opts, :global, false))
          }
        end
      end

      defmacro defexternal({name, _, args}) do
        args = Enum.map(args, fn
          {:\\, meta0, [{name, meta, atom}, value]} ->
            name = String.to_atom("_" <> Atom.to_string(name))
            {:\\, meta0, [{name, meta, atom}, value]}

          {name, meta, atom} ->
            name = String.to_atom("_" <> Atom.to_string(name))
            {name, meta, atom}

          other ->
            other
        end)

        quote do
          def unquote(name)(unquote_splicing(args)), do: nil
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation with callback" do
    """
    defmodule Foo do
      @callback is_bar
      @callback is_bar(a)
    end

    defmodule FooImpl do
      @behaviour Foo

      @impl Foo
      def is_bar do
      end

      @impl Foo
      def is_bar(a) when is_binary(a) do
      end

      @impl Foo
      def is_bar(a) do
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should report a violation with false negatives" do
    """
    defmodule FooImpl do
      def impl(false), do: false
      def impl(true), do: true
      def is_bar do
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation with false negatives /2" do
    """
    defmodule FooImpl do
      impl(true)
      def is_bar do
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation with false negatives /3" do
    """
    defmodule Foo do
      @impl is_bar(a)
    end
    defmodule FooImpl do
      def is_bar do
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation with false negatives /4" do
    """
    defmodule Foo do
      @impl true
    end
    defmodule FooImpl do
      def is_bar do
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    """
    def is_valid? do
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /2" do
    """
    def is_valid do
    end
    defp is_attachment? do
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues()
  end

  test "it should report a violation with arity" do
    """
    def is_valid?(a) do
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "is_valid?"
    end)
  end

  test "it should report a violation with arity /2" do
    """
    def is_valid(a) do
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "is_valid"
    end)
  end
end
