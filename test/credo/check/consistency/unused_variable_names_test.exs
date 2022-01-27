defmodule Credo.Check.Consistency.UnusedVariableNamesTest do
  use Credo.Test.Case

  @described_check Credo.Check.Consistency.UnusedVariableNames

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
end
