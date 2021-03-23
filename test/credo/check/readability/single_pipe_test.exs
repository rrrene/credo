defmodule Credo.Check.Readability.SinglePipeTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.SinglePipe

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun do
        some_val
        |> do_something
        |> do_something_else
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun do
        some_val |> do_something
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation for multiple violations" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun do
        some_val |> do_something
        some_other_val
        |> do_something
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues()
  end

  test "it should report a violation if piping a 0-arity function and such functions not allowed" do
    """
    defmodule CredoSampleModule do
      defmodule OtherModule do
        def foo, do: nil
        def bar(nil), do: nil
      end

      defmodule CredoSampleModule do
        def test do
          OtherModule.foo() |> bar()
          foo() |> OtherModule.bar()
          foo() |> bar()

          foo_anonymous = fn ->
            nil
          end

          foo_anonymous.() |> bar()
        end

        def foo(), do: nil
        def bar(nil), do: nil
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issues()
  end

  test "it should NOT report violation when piping 0-arity function and such functions allowed" do
    """
    defmodule OtherModule do
      def foo, do: nil
      def bar(nil), do: nil
    end

    defmodule CredoSampleModule do
      def test do
        OtherModule.foo() |> bar()
        foo() |> OtherModule.bar()
        foo() |> bar()

        foo_anonymous = fn ->
          nil
        end

        foo_anonymous.() |> bar()
      end

      def foo(), do: nil
      def bar(nil), do: nil
    end
    """
    |> to_source_file()
    |> run_check(@described_check, allow_0_arity_functions: true)
    |> refute_issues()
  end

  test "it should report violation when piping non-function and 0-arity functions allowed" do
    """
    defmodule CredoSampleModule do
      def test do
        :foo |> bar()

        foo = "foo"
        bar |> foo()
      end

      def bar(_), do: nil
    end
    """
    |> to_source_file()
    |> run_check(@described_check, allow_0_arity_functions: true)
    |> assert_issues()
  end

end
