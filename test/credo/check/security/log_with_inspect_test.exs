defmodule Credo.Check.Security.LogWithInspectTest do
  use Credo.Test.Case

  alias Credo.Check.Security.LogWithInspect

  describe "LogWithInspect" do
    test "should find an issue when Logger is called with inspect in string interpolation" do
      source = """
      defmodule ExampleModule do
        def my_function(var1) do
          Logger.info("something \#{inspect(var1)}")
        end
      end
      """

      source
      |> to_source_file()
      |> run_check(LogWithInspect)
      |> assert_issue()
    end

    test "should find an issue when Logger is called with inspect in the anonymous function" do
      source = """
      defmodule ExampleModule do
        def my_function(var1) do
          Logger.info(fn -> "something \#{inspect(var1)}" end)
        end
      end
      """

      source
      |> to_source_file()
      |> run_check(LogWithInspect)
      |> assert_issue()
    end

    test "should not find an issue with Logger" do
      source = """
      defmodule ExampleModule do
        def my_function(var1) do
          Logger.info("hello world")
        end
      end
      """

      source
      |> to_source_file()
      |> run_check(LogWithInspect)
      |> refute_issues()
    end
  end
end
