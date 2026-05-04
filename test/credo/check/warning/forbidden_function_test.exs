defmodule Credo.Check.Warning.ForbiddenFunctionTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.ForbiddenFunction

  #
  # cases NOT raising issues
  #

  test "it should NOT report with default params" do
    """
    defmodule MyModule do
      def decode(data) do
        :erlang.binary_to_term(data)
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check, functions: [])
    |> refute_issues()
  end

  test "allows non-forbidden functions from the same module" do
    """
    defmodule MyModule do
      def safe do
        SomeModule.safe_function(foo)
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check, functions: [{SomeModule, :dangerous_function, "This function is dangerous."}])
    |> refute_issues()
  end

  test "ignores other Erlang functions" do
    """
    defmodule MyModule do
      def my_function do
        :erlang.term_to_binary(%{foo: "bar"})
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check,
      functions: [{:erlang, :binary_to_term, "Use Plug.Crypto.non_executable_binary_to_term/2 instead."}]
    )
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report on different arities" do
    """
    defmodule MyModule do
      def dangerous do
        SomeModule.dangerous_function()
        SomeModule.dangerous_function("foo")
        SomeModule.dangerous_function("foo", "bar")
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check, functions: [{SomeModule, :dangerous_function, "This function is dangerous."}])
    |> assert_issues(3)
  end

  test "it should report on different arities for Erlang calls" do
    """
    defmodule MyModule do
      def decode(data) do
        :erlang.binary_to_term()
        :erlang.binary_to_term("foo")
        :erlang.binary_to_term("foo", "bar")
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check,
      functions: [{:erlang, :binary_to_term, "Use Plug.Crypto.non_executable_binary_to_term/2 instead."}]
    )
    |> assert_issues(3)
  end

  test "it should report on nested module names" do
    """
    defmodule MyModule do
      def call do
        Some.Nested.Module.forbidden_func()
        __MODULE__.Nested.Module.fun()
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check, functions: [{Some.Nested.Module, :forbidden_func, "Don't use this."}])
    |> assert_issue(%{
      trigger: "Some.Nested.Module.forbidden_func",
      message: ~r"Don't use this."
    })
  end

  test "it should report on multiple violations" do
    """
    defmodule MyModule do
      def decode(data) do
        :erlang.binary_to_term(data)
      end

      def other do
        SomeModule.dangerous_function(:arg)
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check,
      functions: [
        {:erlang, :binary_to_term, "Use safe alternative."},
        {SomeModule, :dangerous_function, "This is dangerous."}
      ]
    )
    |> assert_issues(2)
    |> assert_issues_match([%{message: "Use safe alternative."}, %{message: "This is dangerous."}])
  end

  test "it should report on piped calls" do
    """
    defmodule MyModule do
      def decode(data) do
        data
        |> Base.decode64!()
        |> :erlang.binary_to_term()
        |> IO.inspect()
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check,
      functions: [{:erlang, :binary_to_term, "Use Plug.Crypto.non_executable_binary_to_term/2 instead."}]
    )
    |> assert_issue()
  end
end
