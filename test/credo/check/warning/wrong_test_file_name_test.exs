defmodule Credo.Check.Warning.WrongTestFileNameTest do
  use Credo.Test.Case, async: true

  alias Credo.Check.Warning.WrongTestFileName

  for test_module <- [ExUnit.Case, MyApp.ConnCase, MyApp.TestCases.DataCase, MyApp.E2ECase] do
    test "alerts on `use #{test_module}` in a non-test file" do
      """
      defmodule MyModule do
        use #{unquote(test_module)}

        def some_function do
          :ok
        end
      end
      """
      |> to_source_file("lib/my_module.ex")
      |> run_check(WrongTestFileName)
      |> assert_issue()
    end

    test "alerts on `use #{test_module}` with options in a non-test file" do
      """
      defmodule MyModule do
        use #{unquote(test_module)}, async: true

        def some_function do
          :ok
        end
      end
      """
      |> to_source_file("lib/my_module.ex")
      |> run_check(WrongTestFileName)
      |> assert_issue()
    end

    test "alerts on `use #{test_module}` with multiple options in a non-test file" do
      """
      defmodule MyModule do
        use #{unquote(test_module)}, async: false, group: :some_group

        def some_function do
          :ok
        end
      end
      """
      |> to_source_file("lib/my_module.ex")
      |> run_check(WrongTestFileName)
      |> assert_issue()
    end

    test "does not alert on `use #{test_module}` in a properly named test file" do
      for opts <- ["", ", async: true", ", async: false, group: :some_group"] do
        """
        defmodule MyModuleTest do
          use #{unquote(test_module)}#{opts}

          test "some test" do
            assert true
          end
        end
        """
        |> to_source_file("lib/my_module_test.exs")
        |> run_check(WrongTestFileName)
        |> refute_issues()
      end
    end
  end

  test "does not alert on other use statements in non-test files" do
    """
    defmodule MyModule do
      use GenServer
      use Phoenix.LiveView
      use MyApp.Cases
      use MyApp.Cases, async: true
      use MyApp.Cases, async: true, group: :some_group

      def some_function do
        :ok
      end
    end
    """
    |> to_source_file("lib/my_module.ex")
    |> run_check(WrongTestFileName)
    |> refute_issues()
  end
end
