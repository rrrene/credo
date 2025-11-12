defmodule Credo.Check.Refactor.PassAsyncInTestCasesTest do
  use Credo.Test.Case, async: true

  @described_check Credo.Check.Refactor.PassAsyncInTestCases

  #
  # cases NOT raising issues
  #

  test "it ignores `use` statements for modules not ending in 'Case'" do
    ~S'''
    defmodule FooTest do
      use SomeModule
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  for case_name <- ~w[MyApp.DataCase ConnCase Foo.Bar.BazCase] do
    #
    # cases NOT raising issues
    #

    @case_name case_name

    test "it allows `use #{@case_name}, async: true`" do
      ~s'''
      defmodule FooTest do
        use #{@case_name}, async: true
      end
      '''
      |> to_source_file()
      |> run_check(@described_check)
      |> refute_issues()
    end

    test "it allows `use #{@case_name}, async: false`" do
      ~s'''
      defmodule BlahTest do
        use #{@case_name}, async: false
      end
      '''
      |> to_source_file()
      |> run_check(@described_check)
      |> refute_issues()
    end

    #
    # cases raising issues
    #

    test "it does not allow `use #{@case_name}` with other options but not `async:`" do
      ~s'''
      defmodule ThingTest do
        use #{@case_name}, bite_strength: :xtreme
      end
      '''
      |> to_source_file()
      |> run_check(@described_check)
      |> assert_issue(fn issue ->
        assert issue.line_no == 2
        assert issue.trigger == "use"
      end)
    end

    test "it does not allow `use #{@case_name}` without options" do
      ~s'''
      defmodule FooTest do
        # some comment
        use #{@case_name}
      end
      '''
      |> to_source_file()
      |> run_check(@described_check)
      |> assert_issue(fn issue ->
        assert issue.line_no == 3
        assert issue.trigger == "use"
      end)
    end
  end
end
