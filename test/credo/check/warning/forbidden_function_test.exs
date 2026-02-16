defmodule Credo.Check.Warning.ForbiddenFunctionTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.ForbiddenFunction

  @binary_to_term_error "Use Plug.Crypto.non_executable_binary_to_term/2 instead."

  @erlang_binary_to_term_config [
    functions: [
      {:erlang, :binary_to_term, @binary_to_term_error}
    ]
  ]

  test "produces no issues when no functions configured" do
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

  describe "Erlang function calls" do
    test "will alert on any arity" do
      for function_args <- ["", "foo", "foo, bar"] do
        """
        defmodule MyModule do
          def decode(data) do
            :erlang.binary_to_term(#{function_args})
          end
        end
        """
        |> to_source_file()
        |> run_check(@described_check, @erlang_binary_to_term_config)
        |> assert_issue(fn issue ->
          assert issue.trigger == ":erlang.binary_to_term"
          assert issue.message == ":erlang.binary_to_term is forbidden: #{@binary_to_term_error}"
        end)
      end
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
      |> run_check(@described_check, @erlang_binary_to_term_config)
      |> refute_issues()
    end
  end

  describe "Elixir function calls" do
    test "will alert on any arity" do
      error_message = "This function is dangerous."

      for function_args <- ["", "foo", "foo, bar"] do
        """
        defmodule MyModule do
          def dangerous do
            SomeModule.dangerous_function(#{function_args})
          end
        end
        """
        |> to_source_file()
        |> run_check(@described_check,
          functions: [
            {SomeModule, :dangerous_function, error_message}
          ]
        )
        |> assert_issue(fn issue ->
          assert issue.trigger == "SomeModule.dangerous_function"
          assert issue.message == "SomeModule.dangerous_function is forbidden: #{error_message}"
        end)
      end
    end

    test "handles nested module names" do
      custom_error = "Don't use this."

      """
      defmodule MyModule do
        def call do
          Some.Nested.Module.forbidden_func()
        end
      end
      """
      |> to_source_file()
      |> run_check(@described_check,
        functions: [
          {Some.Nested.Module, :forbidden_func, custom_error}
        ]
      )
      |> assert_issue(fn issue ->
        assert issue.trigger == "Some.Nested.Module.forbidden_func"
        assert issue.message == "Some.Nested.Module.forbidden_func is forbidden: #{custom_error}"
      end)
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
      |> run_check(@described_check,
        functions: [
          {SomeModule, :dangerous_function, "This function is dangerous."}
        ]
      )
      |> refute_issues()
    end
  end

  test "detects multiple violations" do
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
    |> assert_issues(fn issues ->
      messages = Enum.map(issues, & &1.message) |> Enum.sort()
      assert [":erlang.binary_to_term" <> _, "SomeModule.dangerous_function" <> _] = messages
    end)
  end

  test "handles piped calls" do
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
    |> run_check(@described_check, @erlang_binary_to_term_config)
    |> assert_issue()
  end
end
