defmodule Credo.Check.Refactor.PassAsyncInTestCasesTest do
  use Credo.Test.Case, async: true

  @described_check Credo.Check.Refactor.PassAsyncInTestCases

  test "it ignores `use` statements for modules not ending in 'Case'" do
    """
    defmodule FooTest do
      use SomeModule
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  for case_name <- ~w[MyApp.DataCase ConnCase Foo.Bar.BazCase] do
    @case_name case_name

    test "it allows `use #{@case_name}, async: true`" do
      """
      defmodule FooTest do
        use #{@case_name}, async: true
      end
      """
      |> to_source_file()
      |> run_check(@described_check)
      |> refute_issues()
    end

    test "it allows `use #{@case_name}, async: false`" do
      """
      defmodule BlahTest do
        use #{@case_name}, async: false
      end
      """
      |> to_source_file()
      |> run_check(@described_check)
      |> refute_issues()
    end

    test "it does not allow `use #{@case_name}` with other options but not `async:`" do
      """
      defmodule ThingTest do
        use #{@case_name}, bite_strength: :xtreme
      end
      """
      |> to_source_file()
      |> run_check(@described_check)
      |> assert_issue(fn issue ->
        assert issue.line_no == 2

        if has_quoted_to_algebra?() do
          assert issue.column == 3
          assert issue.trigger == "use #{@case_name}, bite_strength: :xtreme"
        end
      end)
    end

    test "it does not allow `use #{@case_name}` without options" do
      """
      defmodule FooTest do
        # some comment
        use #{@case_name}
      end
      """
      |> to_source_file()
      |> run_check(@described_check)
      |> assert_issue(fn issue ->
        assert issue.line_no == 3

        if has_quoted_to_algebra?() do
          assert issue.column == 3
          assert issue.trigger == "use #{@case_name}"
        end
      end)
    end
  end

  def has_quoted_to_algebra? do
    function_exported?(Code, :quoted_to_algebra, 1)
  end
end
