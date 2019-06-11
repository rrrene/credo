defmodule Credo.Check.Consistency.UnusedVariableNamesTest do
  use Credo.TestHelper

  @described_check Credo.Check.Consistency.UnusedVariableNames

  test "it should NOT report correct behaviour" do
    [
      """
      defmodule Credo.SampleOne do
        defmodule Foo do
          def bar(_, %{foo: foo} = _, _) do
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
    |> refute_issues(@described_check)
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
    |> refute_issues(@described_check)
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
    |> assert_issue(@described_check, fn issue ->
      assert "_item" == issue.trigger
      assert 4 == issue.line_no
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
    |> assert_issue(@described_check, fn issue ->
      assert "_" == issue.trigger
      assert 3 == issue.line_no
    end)
  end
end
