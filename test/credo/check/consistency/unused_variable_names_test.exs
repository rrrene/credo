defmodule Credo.Check.Consistency.UnusedVariableNamesTest do
  use Credo.Test.Case

  @described_check Credo.Check.Consistency.UnusedVariableNames

  #
  # cases NOT raising issues
  #

  test "it should NOT report correct behaviour" do
    [
      """
      defmodule Credo.SampleOne do
        defmodule Foo do
          def bar(_, %{foo: foo} = _, _) do
            version = Mix.Project.config()[:version]
          end
        end
      end
      """,
      """
      defmodule Credo.SampleTwo do
        defmodule Foo do
          def bar(list) do
            Enum.map(list, fn _ -> 1 end)
          end
        end
      end
      """
    ]
    |> to_source_files
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report correct behaviour (only one unused variable, the other a special variable)" do
    [
      """
      defmodule UnusedVariableModule do
        defp a do
          _ = __MODULE__
        end
      end
      """
    ]
    |> to_source_files
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report correct behaviour (only one unused variable)" do
    [
      """
      defmodule Credo.SampleOne do
        defmodule Foo do
          def bar(_, _, _) do
          end
        end
      end
      """,
      """
      defmodule Credo.SampleTwo do
      end
      """
    ]
    |> to_source_files
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report functions starting with `_` (only variables)" do
    [
      """
      defmodule Credo.SampleOne do
        defmodule Foo do
          def __some_function__(var1, var2) do
          end

          def bar(x1, x2, x3), do: nil
          def bar2(x1, x2, x3), do: nil
          def bar3(x1, x2, x3), do: nil
          def bar4(x1, x2, x3), do: nil
          def bar5(x1, x2, x3), do: nil
        end
      end
      """,
      """
      defmodule Credo.SampleTwo do
        def _some_other_function(var1, var2) do
        end
      end
      """
    ]
    |> to_source_files
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation for different naming schemes (expects anonymous)" do
    [
      """
      defmodule Credo.SampleOne do
        defmodule Foo do
          def bar(_, _, _) do
          end
        end
      end
      """,
      """
      defmodule Credo.SampleTwo do
        defmodule Foo do
          def bar(list) do
            Enum.map(list, fn _item -> 1 end)
          end
        end
      end
      """
    ]
    |> to_source_files
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert "_item" == issue.trigger
      assert 4 == issue.line_no
    end)
  end

  test "it should report a violation for different naming schemes with guards (expects anonymous)" do
    [
      """
      defmodule Credo.SampleOne do
        defmodule Foo do
          def bar(_, _, _) do
          end
        end
      end
      """,
      """
      defmodule Credo.SampleTwo do
        defmodule Foo do
          def bar(_, x2, _x3) when is_nil(x2) do
          end
        end
      end
      """
    ]
    |> to_source_files
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert "_x3" == issue.trigger
      assert 3 == issue.line_no
    end)
  end

  test "it should report a violation for different naming schemes (expects meaningful)" do
    [
      """
      defmodule Credo.SampleOne do
        defmodule Foo do
          def bar(name, _) do
            case name do
              "foo" <> _name -> "FOO"
              "bar" <> _name -> "BAR"
              _name -> "DEFAULT"
            end
          end
        end
      end
      """,
      """
      defmodule Credo.SampleTwo do
        defmodule Foo do
          def bar(list) do
            Enum.map(list, fn _item -> 1 end)
          end
        end
      end
      """
    ]
    |> to_source_files
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert "_" == issue.trigger
      assert 3 == issue.line_no
    end)
  end

  test "it should report a violation for different naming schemes with guards (expects meaningful)" do
    [
      """
      defmodule Credo.SampleOne do
        defmodule Foo do
          def bar(name, _) when is_binary(name) do
            case name do
              "foo" <> _name -> "FOO"
              "bar" <> _name -> "BAR"
              _name -> "DEFAULT"
            end
          end
        end
      end
      """,
      """
      defmodule Credo.SampleTwo do
        defmodule Foo do
          def bar(list) do
            Enum.map(list, fn _item -> 1 end)
          end
        end
      end
      """
    ]
    |> to_source_files
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert "_" == issue.trigger
      assert 3 == issue.line_no
    end)
  end

  test "it should report a violation for different naming schemes in a two elem tuple match (expects meaningful)" do
    [
      """
      defmodule Credo.SampleOne do
        defmodule Foo do
          def bar(x1, x2) do
            {_a, _b} = x1
            {_c, _} = x2
          end
        end
      end
      """,
      """
      defmodule Credo.SampleTwo do
        defmodule Foo do
          def bar(x1, x2) do
            with {:ok, _} <- x1,
                 {:ok, _b} <- x2, do: :ok
          end
        end
      end
      """
    ]
    |> to_source_files()
    |> run_check(@described_check)
    |> assert_issues(fn issues ->
      assert length(issues) == 2

      assert Enum.find(issues, &match?(%{trigger: "_", line_no: 5}, &1))
      assert Enum.find(issues, &match?(%{trigger: "_", line_no: 4}, &1))
    end)
  end

  test "it should report a violation for different naming schemes with a map match (expects meaningful)" do
    [
      """
      defmodule Credo.SampleOne do
        defmodule Foo do
          def bar(%{a: _a, b: _b, c: _}) do
            :ok
          end
        end
      end
      """,
      """
      defmodule Credo.SampleTwo do
        defmodule Foo do
          def bar(map) do
            case map do
              %{a: _} -> :ok
              _map -> :error
            end
          end
        end
      end
      """
    ]
    |> to_source_files()
    |> run_check(@described_check)
    |> assert_issues(fn issues ->
      assert length(issues) == 2

      assert Enum.find(issues, &match?(%{trigger: "_", line_no: 3}, &1))
      assert Enum.find(issues, &match?(%{trigger: "_", line_no: 5}, &1))
    end)
  end

  test "it should report a violation for different naming schemes with a list match (expects meaningful)" do
    [
      """
      defmodule Credo.SampleOne do
        defmodule Foo do
          def bar(list) do
            case list do
              [] -> :empty
              [head | _] -> head
            end
          end
        end
      end
      """,
      """
      defmodule Credo.SampleTwo do
        defmodule Foo do
          def bar([_a, _b | rest]) do
            rest
          end
        end
      end
      """
    ]
    |> to_source_files()
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert "_" == issue.trigger
      assert 6 == issue.line_no
    end)
  end

  test "it should report a violation for different naming schemes with a macro (expects meaningful)" do
    [
      """
      defmodule Credo.SampleOne do
        defmodule Foo do
          defmacro __using__(_) do
          end
        end

        def bar(_opts) do
        end
      end
      """,
      """
      defmodule Credo.SampleTwo do
        defmodule Foo do
          defmacrop bar(_opts) do
          end
        end
      end
      """
    ]
    |> to_source_files()
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert "_" == issue.trigger
      assert 3 == issue.line_no
    end)
  end

  test "it should report a violation for naming schemes other than the forced one" do
    [
      """
      defmodule Credo.SampleOne do
        defmodule Foo do
          def bar(name, _) when is_binary(name) do
            case name do
              "foo" <> _name -> "FOO"
              "bar" <> _name -> "BAR"
              _name -> "DEFAULT"
            end
          end
        end
      end
      """,
      """
      defmodule Credo.SampleTwo do
        defmodule Foo do
          def bar(list) do
            Enum.map(list, fn _item -> 1 end)
          end
        end
      end
      """
    ]
    |> to_source_files
    |> run_check(@described_check, force: :anonymous)
    |> assert_issues(fn issues ->
      assert Enum.count(issues) == 4

      assert Enum.any?(issues, fn issue ->
               issue.trigger == "_name"
             end)

      assert Enum.any?(issues, fn issue ->
               issue.trigger == "_item"
             end)
    end)
  end

  test "it should report a violation once" do
    [
      """
      defmodule Foo do
        def bar(["a" <> _a] = assigns), do: :ok
        def baz(["a" <> _] = assigns), do: :ok
      end
      """
    ]
    |> to_source_files
    |> run_check(@described_check)
  end

  test "it should report only a single violation for naming schemes other than the forced one" do
    [
      ~S'''
      defmodule FooWeb.CoreComponents do
        @moduledoc false

        def icon(%{name: "hero-" <> _} = assigns) do
          ~H"""
          <span class={[@name, @class]} />
          """
        end
      end
      ''',
      ~S'''
      defmodule Foo do
        @moduledoc """
        Documentation for `Foo`.
        """
      end
      '''
    ]
    |> to_source_files
    |> run_check(@described_check, force: :meaningful)
    |> assert_issue()
  end
end
